/*
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *
 */
#include <Timer.h>
#include "includes/command.h"
#include "includes/packet.h"
#include "includes/CommandMsg.h"
#include "includes/sendInfo.h"
#include "includes/channels.h"
#include "includes/protocol.h"

#define MAXNODES 20



//Project 1
/*typedef nx_struct neighbor {
    nx_uint16_t Node;
    nx_uint16_t Age;
} neighbor;*/

//Project 2

typedef nx_struct lspLink {
	nx_uint16_t src;
	nx_uint16_t cost;
	nx_uint16_t neighbor;

} lspLink;




module Node{
   uses interface Boot;
   uses interface SplitControl as AMControl;
   uses interface Receive;
   uses interface SimpleSend as Sender;
   uses interface CommandHandler;
   uses interface List<pack> as nodesVisited;
   uses interface List<pack> as ListOfNeighbors;

	//Project 2
  uses interface Hashmap<int> as routingTable;
  uses interface Random as Random;
  uses interface List<lspLink> as lspLinkList;
  uses interface Timer<TMilli> as NeighborDiscoveryTimer;
  uses interface Timer<TMilli> as dijkstraTimer;
  uses interface Timer<TMilli> as lsrTimer;
  uses interface RoutingTable;

	//project 3
  uses interface Transport;

}

implementation{
   	pack sendPackage;
   	uint16_t sequence = 1;
   	pack currentNeighbor;
	char* neighborPayload = "Neighbor Discovery";
	void concatenate(char* original, char* add);
	bool checkNeighbors(pack *Package);
	bool pkgValid(pack *Package);
	//void dijkstraTimerFired();
	//void lsrTimer();
        void LinkStateStart();
	void NeighborDiscoveryStart();
	//Proj 2 Global Variables
	lspLink lsp;
	uint16_t lspAge = 0;
	bool valInArray(uint16_t val, uint16_t *arr, uint16_t size);
	int graph();

	//project3
	socket_t fd[10];
	uint8_t fdIndex = 0;


   // Prototypes
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);
	
	//uint sequence
   event void Boot.booted(){
      call AMControl.start();
      dbg(GENERAL_CHANNEL, "Booted\n");
	NeighborDiscoveryStart();      
	LinkStateStart();
   }

   event void AMControl.startDone(error_t err){
      if(err == SUCCESS){
         dbg(GENERAL_CHANNEL, "Radio On\n");
      }else{
         //Retry until successful
         call AMControl.start();
      }
   }

   event void AMControl.stopDone(error_t err){}

   event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
      //dbg(GENERAL_CHANNEL, "Packet Received\n");
      if(len==sizeof(pack)){
         pack* myMsg=(pack*) payload;
         //dbg(GENERAL_CHANNEL, "Package Payload: %s\n", myMsg->payload);
 
	if(myMsg->protocol == PROTOCOL_TCP) {
		//dbg(ROUTING_CHANNEL, "HERE\n");
		if(TOS_NODE_ID == myMsg->dest) {
			//dbg(FLOODING_CHANNEL, "Success!: Package from Node: %d, at destination Node: %d, Package Payload: %s\n\n", myMsg->src, myMsg->dest, myMsg->payload);
			call Transport.receive(myMsg);
			return msg;
		}else {
			if(call routingTable.contains(myMsg -> src)){
              			//dbg(NEIGHBOR_CHANNEL, "to get to:%d, send through:%d\n", myMsg -> dest, call routingTable.get(myMsg -> dest));
              			makePack(&sendPackage, myMsg->src, myMsg->dest, myMsg->TTL-1, myMsg->protocol, myMsg->seq, (uint8_t *) myMsg->payload, sizeof(myMsg->payload));
              			call Sender.send(sendPackage, call routingTable.get(myMsg -> dest));
            		}else{
              			//dbg(NEIGHBOR_CHANNEL, "Couldn't find the routing table for:%d so flooding\n",TOS_NODE_ID);
              			makePack(&sendPackage, myMsg->src, myMsg->dest, myMsg->TTL-1, myMsg->protocol, myMsg->seq, (uint8_t *) myMsg->payload, sizeof(myMsg->payload));
              			call Sender.send(sendPackage, AM_BROADCAST_ADDR);
            		}	
		}
		
	}else if(myMsg->protocol == PROTOCOL_PING) {

		if(!pkgValid(myMsg)) {
		//dbg(FLOODING_CHANNEL, "Package removed\n\n");
		return msg;
		}
		if(TOS_NODE_ID == myMsg->dest) {
			dbg(FLOODING_CHANNEL, "Success!: Package from Node: %d, at destination Node: %d, Package Payload: %s\n\n", myMsg->src, myMsg->dest, myMsg->payload);
			return msg;
		}else {
			if(call routingTable.contains(myMsg -> src)){
              			dbg(NEIGHBOR_CHANNEL, "to get to:%d, send through:%d\n", myMsg -> dest, call routingTable.get(myMsg -> dest));
              			makePack(&sendPackage, myMsg->src, myMsg->dest, myMsg->TTL-1, myMsg->protocol, myMsg->seq, (uint8_t *) myMsg->payload, sizeof(myMsg->payload));
              			call Sender.send(sendPackage, call routingTable.get(myMsg -> dest));
            		}else{
              			//dbg(NEIGHBOR_CHANNEL, "Couldn't find the routing table for:%d so flooding\n",TOS_NODE_ID);
              			makePack(&sendPackage, myMsg->src, myMsg->dest, myMsg->TTL-1, myMsg->protocol, myMsg->seq, (uint8_t *) myMsg->payload, sizeof(myMsg->payload));
              			call Sender.send(sendPackage, AM_BROADCAST_ADDR);
            		}	
		}
		
	}else if(myMsg->protocol == PROTOCOL_PINGREPLY) {	//handle neighbor discovery package
		if(!pkgValid(myMsg)) {
		//dbg(FLOODING_CHANNEL, "Package removed\n\n");
		return msg;
		}		
		if(checkNeighbors(myMsg)) {
			//dbg(NEIGHBOR_CHANNEL, "New neighbor found!\n");
			call ListOfNeighbors.pushback(*myMsg);			
			makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, 1, myMsg->protocol = PROTOCOL_PINGREPLY, myMsg->seq, (uint8_t*) neighborPayload, PACKET_MAX_PAYLOAD_SIZE);
			call Sender.send(sendPackage, AM_BROADCAST_ADDR);
		}
	}

	if(myMsg->protocol == PROTOCOL_LINKSTATE)
            {
              uint16_t i,j = 0;
              uint16_t k = 0;
              bool enterdata = TRUE;

		if(!pkgValid(myMsg)) {
		//dbg(FLOODING_CHANNEL, "Package removed\n\n");
		return msg;
		}

		//dbg(ROUTING_CHANNEL,"$$$Neighbor: %d\n",myMsg->payload[1]);
              for(i = 0; i < myMsg->seq; i++)
              {
                for(j = 0; j < call lspLinkList.size(); j++)
                {
                  lspLink lspacket = call lspLinkList.get(j);
                  if(lspacket.src == myMsg->src && lspacket.neighbor==myMsg->payload[i])
                  {
                    enterdata = FALSE;
                  }
                }
              }

              if(enterdata)
              {
                for(k = 0; k <= myMsg->seq; k++)
                {
			if(myMsg->payload[k]!=0)
			{
                  		lsp.neighbor = myMsg->payload[k];
                  		lsp.cost = 1;
                  		lsp.src = myMsg->src;
                  		call lspLinkList.pushback(lsp);
				call dijkstraTimer.startOneShot(1000 + (uint16_t)((call Random.rand16())%1000));
			}
                  //dbg(ROUTING_CHANNEL,"$$$Neighbor: %d\n",myMsg->payload[k]);
                }
                makePack(&sendPackage, myMsg->src, AM_BROADCAST_ADDR, myMsg->TTL-1 , PROTOCOL_LINKSTATE, myMsg->seq, myMsg->payload, PACKET_MAX_PAYLOAD_SIZE);
                //Check TOS_NODE_ID and destination
                call Sender.send(sendPackage,AM_BROADCAST_ADDR);
              }
              else{
                //dbg(ROUTING_CHANNEL,"LSP already exists for %d\n",TOS_NODE_ID);
              }
            }	
		return msg;
	
      }
      dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
      return msg;
   }


   event void CommandHandler.ping(uint16_t destination, uint8_t *payload){
      dbg(GENERAL_CHANNEL, "PING EVENT \n");
      if(call routingTable.contains(destination))
        {
          makePack(&sendPackage, TOS_NODE_ID, destination, MAX_TTL, PROTOCOL_PING, sequence, payload, PACKET_MAX_PAYLOAD_SIZE);
          dbg(NEIGHBOR_CHANNEL, "To get to:%d, send through:%d\n", destination, call routingTable.get(destination));
          call Sender.send(sendPackage, call routingTable.get(destination));
        }
        else{
		makePack(&sendPackage, TOS_NODE_ID, destination, MAX_TTL, PROTOCOL_PING, sequence, payload, PACKET_MAX_PAYLOAD_SIZE);
          	dbg(NEIGHBOR_CHANNEL, "No Routing Table for:%d so flooding\n", TOS_NODE_ID);
          	call Sender.send(sendPackage, AM_BROADCAST_ADDR);
        }
	sequence++;
   }
	bool pkgValid(pack* myMsg) {
        	uint16_t list = call nodesVisited.size();
        	uint16_t i = 0;
        
        
       		if (list == 0) {
            		return TRUE;
        	} else if (myMsg->TTL == 0) {
           		return FALSE;
        	} else {
            		for (i = 0; i < list; i++) {
                
                		pack currentPack;
                		currentPack = call nodesVisited.get(i);
                
                		if (currentPack.dest == myMsg->dest && currentPack.seq == myMsg->seq) {
                    		return FALSE;
                	}
           	}
            return TRUE;
        }
    }
	
	void NeighborDiscoveryStart(){
    // one shot timer and include random element to it.
    		uint32_t startTimer;
    		dbg(GENERAL_CHANNEL, "Booted\n");
    		startTimer = (20000 + (uint16_t) ((call Random.rand16())%5000));;
    //call neigbordiscoveryTimer.startPeriodic(startTimer);
    		call NeighborDiscoveryTimer.startOneShot(10000);
  }
	event void NeighborDiscoveryTimer.fired() {
		makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, 1, PROTOCOL_PINGREPLY, sequence, (uint8_t*) neighborPayload, PACKET_MAX_PAYLOAD_SIZE);
		call Sender.send(sendPackage, AM_BROADCAST_ADDR);
	}

	bool checkNeighbors(pack* myMsg) {
		uint16_t list = call ListOfNeighbors.size();
		uint16_t i = 0;

		if(list == 0){
			return TRUE;
		}else {
			for(i=0; i<list; i++) {
				currentNeighbor = call ListOfNeighbors.get(i);
		
				if(currentNeighbor.src == myMsg->src) {
					return FALSE;
				}
			}
		}
		return TRUE;
	}



   event void CommandHandler.printNeighbors(){
	uint16_t list = call ListOfNeighbors.size();
	uint16_t i = 0;
	if (list > 0) {
		for(i = 0; i < list; i++) {
			currentNeighbor = call ListOfNeighbors.get(i);
			dbg(NEIGHBOR_CHANNEL, "NEIGHBORS of Node %d is %d\n", TOS_NODE_ID, currentNeighbor.src);
		}
	} else {
		dbg(NEIGHBOR_CHANNEL, "Node %d has no neighbors\n", TOS_NODE_ID);
	}
   }

   event void CommandHandler.printRouteTable(){
	uint16_t i;
	for (i = 1; i <= call routingTable.size(); i++) {
		dbg(GENERAL_CHANNEL, "Destination %d \t firstHop: %d\n", i, call routingTable.get(i));
	}
}

   event void CommandHandler.printLinkState(){
	if(call lspLinkList.size() > 0) {
		uint16_t lspLinkListSize = call lspLinkList.size();
		uint16_t i = 0;
		for (i = 0; i < lspLinkListSize; i++) {
			lspLink lspackets = call lspLinkList.get(i);
			dbg(ROUTING_CHANNEL, "Source: %d \t Neighbor: %d \t Cost: %d \n", lspackets.src, lspackets.neighbor, lspackets.cost);
		}
	} else {
		dbg(COMMAND_CHANNEL, "No LSP %d \n" , TOS_NODE_ID);
	}
}

   void LinkStateStart(){
    // one shot timer and include random element to it.
    dbg(GENERAL_CHANNEL, "Booted\n");
    call lsrTimer.startPeriodic(80000 + (uint16_t)((call Random.rand16())%10000));
    call dijkstraTimer.startPeriodic(90000 + (uint16_t)((call Random.rand16())%10000));
}

   event void lsrTimer.fired() {
	uint16_t neighborListSize = call ListOfNeighbors.size();
	uint16_t lspListSize = call lspLinkList.size();

	uint16_t neighborArr[neighborListSize];
	uint16_t i=0;
	uint16_t j;
	bool enterdata = TRUE;
	
	if(lspAge == 90) { //Arbitrary numbrer
		lspAge = 0;
        	for(i = 0; i < lspListSize; i++) {
			call lspLinkList.popfront();
		}
	}
	
	for(i = 0; i < neighborListSize; i++) {
		pack neighborNode = call ListOfNeighbors.get(i);
      		for(j = 0; j < lspListSize; j++) {
			lspLink lspackets = call lspLinkList.get(j);
			if(lspackets.src == TOS_NODE_ID && lspackets.neighbor ==neighborNode.src) {
				enterdata = FALSE;
			}
		}
		if (enterdata) {
			lsp.neighbor = neighborNode.src;
       			lsp.cost = 1;
        		lsp.src = TOS_NODE_ID;
        		call lspLinkList.pushback(lsp);
			call dijkstraTimer.startOneShot(1000 + (uint16_t)((call Random.rand16())%1000));
		}
		if(!valInArray(neighborNode.src, neighborArr, neighborListSize)) {
			neighborArr[i] = neighborNode.src;
			//dbg(NEIGHBOR_CHANNEL, "neighbor array: %d\n", neighborArr[i]);
			
			
		}
	}
	makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, MAX_TTL, PROTOCOL_LINKSTATE, neighborListSize, (uint8_t *)neighborArr, PACKET_MAX_PAYLOAD_SIZE);
        call Sender.send(sendPackage, AM_BROADCAST_ADDR);
}

    bool valInArray(uint16_t val, uint16_t *arr, uint16_t size){
	int i;
        for (i = 0; i < size; i++) {
        if (arr[i] == val)
           return TRUE;
        }
      return FALSE;
    }

   
   event void dijkstraTimer.fired() {
	int nodesize[MAXNODES];
	int size = call lspLinkList.size();
	int maxNode = MAXNODES;
	int i;
	int j;
	int nextHop;
	int cost[maxNode][maxNode];
	int distance[maxNode];
	int pre[maxNode];
	int visited[maxNode];
	int nodeCount;
	int minDistance;
	int nextNode;
	int start = TOS_NODE_ID;
	bool matrix[maxNode][maxNode];
	int inf = 10000;
	//dbg(ROUTING_CHANNEL, "working\n");
	for (i = 0; i < maxNode; i++) {
		for(j = 0; j < maxNode; j++) {
			matrix[i][j] = FALSE;
		}
	}

	for(i = 0; i < size; i++) {
		lspLink temp = call lspLinkList.get(i);
		matrix[temp.src][temp.neighbor] = TRUE;
	}

	for(i = 0; i < maxNode; i++) {
		for(j = 0; j < maxNode; j++) {
			if (matrix[i][j] == 0) {
				cost[i][j] = inf;
			} else {
				cost[i][j] = matrix[i][j];
			}
		}
	}

	for (i = 0; i < maxNode; i++) {
		distance[i] = cost[start][i];
		pre[i] = start;
		visited[i] = 0;
	}

	distance[start] = 0;
	visited[start] = 1;
	nodeCount = 1;

	while (nodeCount < maxNode - 1) {
		minDistance = inf;
		for (i = 0; i < maxNode; i++) {
			if (distance[i] <= minDistance && !visited[i]) {
				minDistance = distance[i];
				nextNode = i;
			}
		}
		visited[nextNode] = 1;
		for (i = 0; i < maxNode; i++) {
			if (!visited[i]) {
				if (minDistance + cost[nextNode][i] < distance[i]) {
					distance[i] = minDistance + cost[nextNode][i];
					pre[i] = nextNode;
				}
			}
		}
		nodeCount = nodeCount + 1;

	}
	
	for (i = 0; i < maxNode; i++) {
		nextHop = TOS_NODE_ID;
		if (distance[i] != inf) {
			if (i != start) {
				j = i;
				while (j != start) {
					if (j != start) {
						nextHop = j;
					}
					j = pre[j];

				}
			} else {
				nextHop = start;
			} if (nextHop != 0) {
				call routingTable.insert(i, nextHop);
				call RoutingTable.update(i,nextHop);
			}
		}
	}
}

   event void CommandHandler.printDistanceVector(){}

   event void CommandHandler.setTestServer() {
        call Transport.setTestServer();
}

   event void CommandHandler.setTestClient(){
	call Transport.setTestClient();
}

   event void CommandHandler.setChatServer() {
	call Transport.setChatServer();
}
   event void CommandHandler.hello(uint8_t *msg){
	uint8_t i = 6;
	uint8_t j = 0;	
	char username[20];
	uint8_t port;
	while(msg[i] != 32) {
		username[j] = msg[i];
		i++;
		j++;
		
	}
	username[j] = '\0';
	port = msg[i + 1] - 48;
	dbg(TRANSPORT_CHANNEL, "PORT: %d USERNAME: %s\n", port, username);
	dbg(TRANSPORT_CHANNEL, "%s\n", msg );
	call Transport.setChatClient(port, username, msg);
}
   event void CommandHandler.msg(uint8_t *msg){
	call Transport.msg(msg);
}
   event void CommandHandler.whisper(uint8_t *msg){
	call Transport.whisper(msg);
}
   event void CommandHandler.printUsers(uint8_t *msg){
	call Transport.printUsers(msg);
}

   event void CommandHandler.setAppServer(){}

   event void CommandHandler.setAppClient(){}

   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      Package->seq = seq;
      Package->protocol = protocol;
      memcpy(Package->payload, payload, length);
   }

  void concatenate(char* original, char* add) {
	/*while(*original)
		original++;

	while(*add) {
		*original = *add;
		add++;
		original++;
	}
	*original = '\0';
	*/
  }
}
