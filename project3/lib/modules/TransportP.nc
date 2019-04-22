#include "../../includes/socket.h"
#include "../../includes/packet.h"
#include "../../includes/TCPPacket.h"
#include "../../includes/protocol.h"

module TransportP{
   provides interface Transport;

   uses interface Random as Random;
   uses interface SimpleSend as Sender;
   uses interface RoutingTable;
   uses interface List<socket_t> as SocketList;
   uses interface List<pack> as SendPacketQueue;
   uses interface List<pack> as RcvdPacketQueue;
   uses interface Timer<TMilli> as ServerReadTimer;
   uses interface Timer<TMilli> as ClientWriteTimer;
   uses interface Timer<TMilli> as SendTimer;
   uses interface Timer<TMilli> as TimeWait;
   uses interface Timer<TMilli> as TimeoutTimer;
}

implementation{
   uint8_t socketIndex = 1;
   uint8_t maxSockets = 10;
   socket_t activeSockets[10];
   socket_t getSocket(uint8_t destPort, uint8_t srcPort);
   void connectFinish(socket_t fd);

	void connectFinish(socket_t fd) {
		pack myMsg;
		tcp_pack* myTCPPack;
		socket_t mySocket = fd;
		uint8_t i = 0;

		//socket_t server = getSocket(mySocket.dest.port, mySocket.src.port);		
		//server.transfer = fd.transfer;
		//activeSockets[server.fd] = server;
		
		activeSockets[mySocket.fd] = mySocket;
		for (i = 0; i < maxSockets; i++){
			mySocket = activeSockets[i];
			//dbg(TRANSPORT_CHANNEL, "ACTIVE SOCKET: %d\n",mySocket.state);
		}
		call ClientWriteTimer.startPeriodic(100);
		call SendTimer.startOneShot(1000);
				
	}

	socket_t getSocket(uint8_t destPort, uint8_t srcPort){
		socket_t mySocket;
		uint32_t i = 0;
		//uint32_t size = call SocketList.size();
		
		for (i = 0; i < maxSockets; i++){
			mySocket = activeSockets[i];
			if(mySocket.dest.port == srcPort && mySocket.src.port == destPort){
				return mySocket;
			}
		}
		dbg(TRANSPORT_CHANNEL, "COULD NOT LOCATE SOCKET\n");
	}
   	
 /**
    * Get a socket if there is one available.
    * @Side Client/Server
    * @return
    *    socket_t - return a socket file descriptor which is a number
    *    associated with a socket. If you are unable to allocated
    *    a socket then return a NULL socket_t.
    */
  command socket_fd_t Transport.socket(){
   	if(socketIndex <= 10) {
		uint8_t fd = socketIndex;
		socketIndex++;
		return (socket_fd_t)fd;
	}else {
		return (socket_fd_t)NULL;
	}
  }
	
    /**
    * Bind a socket with an address.
    * @param
    *    socket_t fd: file descriptor that is associated with the socket
    *       you are binding.
    * @param
    *    socket_addr_t *addr: the source port and source address that
    *       you are biding to the socket, fd.
    * @Side Client/Server
    * @return error_t - SUCCESS if you were able to bind this socket, FAIL
    *       if you were unable to bind.
    */
  

  command error_t Transport.bind(socket_fd_t fd, socket_addr_t *addr){
	
	
  /**
    * Checks to see if there are socket connections to connect to and
    * if there is one, connect to it.
    * @param
    *    socket_t fd: file descriptor that is associated with the socket
    *       that is attempting an accept. remember, only do on listen.
    * @side Server
    * @return socket_t - returns a new socket if the connection is
    *    accepted. this socket is a copy of the server socket but with
    *    a destination associated with the destination address and port.
    *    if not return a null socket.
    */
  }

  command socket_t Transport.accept(socket_t server){
	//uint16_t size = call SocketList.size();
	uint16_t i = 0;
	socket_t mySocket;
	
	for(i = 0; i < maxSockets; i++) {
		mySocket = activeSockets[i];
		if(mySocket.dest.port == server.src.port && server.state == LISTEN) {
			dbg(ROUTING_CHANNEL, "CLIENT FOUND\n");
			server.dest.addr = mySocket.src.addr;
			server.dest.port = mySocket.src.port;
			return server;
		}
	}
	
	
   /**
    * Write to the socket from a buffer. This data will eventually be
    * transmitted through your TCP implimentation.
    * @param
    *    socket_t fd: file descriptor that is associated with the socket
    *       that is attempting a write.
    * @param
    *    uint8_t *buff: the buffer data that you are going to wrte from.
    * @param
    *    uint16_t bufflen: The amount of data that you are trying to
    *       submit.
    * @Side For your project, only client side. This could be both though.
    * @return uint16_t - return the amount of data you are able to write
    *    from the pass buffer. This may be shorter then bufflen
    */
  

  }

  command uint16_t Transport.write(socket_t fd, uint8_t *buff, uint16_t bufflen){
	uint16_t i = fd.lastWritten;
	uint16_t bytesWritten = 0;
	pack myMsg;
	tcp_pack* myTCPPack;
	
	myTCPPack = (tcp_pack*)(myMsg.payload);
	myTCPPack->flag = DATA_FLAG;
	myTCPPack->srcPort = fd.src.port;
	myTCPPack->destPort = fd.dest.port;
	
	for(i = fd.lastWritten; i < fd.transfer && i < bufflen; i++) {
		if(call SendPacketQueue.size() < 20) {
			myTCPPack->payload[0] = buff[i];
			myTCPPack->seq = i + 1;
			dbg(TRANSPORT_CHANNEL, "%hu\n", myTCPPack->seq);
			call Transport.makePack(&myMsg, TOS_NODE_ID, fd.dest.addr, 20, PROTOCOL_TCP, 0, myTCPPack, PACKET_MAX_PAYLOAD_SIZE);
		
			call SendPacketQueue.pushback(myMsg);
			bytesWritten++;
		}else {
			return bytesWritten;
		}
	}

	return bytesWritten;
   /**
    * This will pass the packet so you can handle it internally.
    * @param
    *    pack *package: the TCP packet that you are handling.
    * @Side Client/Server
    * @return uint16_t - return SUCCESS if you are able to handle this
    *    packet or FAIL if there are errors.
    */

  }
  
  command uint16_t Transport.read(socket_t fd, uint8_t *buff, uint16_t bufflen){
  	uint16_t i = fd.lastRead;
	uint16_t bytesRead = 0;
	pack myMsg;
	tcp_pack* myTCPPack;
	
	myTCPPack = (tcp_pack*)(myMsg.payload);
	dbg(TRANSPORT_CHANNEL, "READING DATA...\n");
	//for(i = fd.lastRead;  i < fd.transfer; i++) {
		//if((call SendPacketQueue.size()) < 20) {
			buff[fd.lastRead + 1] = myTCPPack->payload[0];
			myTCPPack->ACK = fd.lastRead + 1;
			myTCPPack->flag = DATA_ACK_FLAG;
			myTCPPack->srcPort = fd.src.port;
			myTCPPack->destPort = fd.dest.port;
			dbg(TRANSPORT_CHANNEL, "%hhu\n", myTCPPack->ACK);
			call Transport.makePack(&myMsg, TOS_NODE_ID, fd.dest.addr, 20, PROTOCOL_TCP, 0, myTCPPack, PACKET_MAX_PAYLOAD_SIZE);
		
			call Sender.send(myMsg, (call RoutingTable.get(fd.dest.addr)));
			bytesRead++;
		//}else {
			//return bytesRead;
		//}
	//}

	
	return bytesRead;
	
     /**
    * Attempts a connection to an address.
    * @param
    *    socket_t fd: file descriptor that is associated with the socket
    *       that you are attempting a connection with.
    * @param
    *    socket_addr_t *addr: the destination address and port where
    *       you will atempt a connection.
    * @side Client
    * @return socket_t - returns SUCCESS if you are able to attempt
    *    a connection with the fd passed, else return FAIL.
    */
  }
  
  command error_t Transport.connect(socket_t fd){
	socket_t mySocket = fd;
	pack myMsg;
	tcp_pack* myTCPpack;
	uint8_t i = 0;
	//dbg(TRANSPORT_CHANNEL, "ADDR %d\n",mySocket.dest.addr );
	myTCPpack = (tcp_pack*)(myMsg.payload);
	myTCPpack->srcPort = mySocket.src.port;
	myTCPpack->destPort = mySocket.dest.port;
	myTCPpack->flag = SYN_FLAG;
	myTCPpack->seq = 1;

	call Transport.makePack(&myMsg, TOS_NODE_ID, mySocket.dest.addr, 20, PROTOCOL_TCP, 27, myTCPpack, PACKET_MAX_PAYLOAD_SIZE);
	mySocket.state = SYN_SENT;

	dbg(TRANSPORT_CHANNEL, "CLIENT CONNECTING...%d\n",mySocket.dest.addr);

	call Sender.send(myMsg, (call RoutingTable.get(mySocket.dest.addr)));

	
  /**
    * Closes the socket.
    * @param
    *    socket_t fd: file descriptor that is associated with the socket
    *       that you are closing.
    * @side Client/Server
    * @return socket_t - returns SUCCESS if you are able to attempt
    *    a closure with the fd passed, else return FAIL.
    */
  }
   command error_t Transport.close(socket_t fd){
        pack myMsg;
	tcp_pack* myTCPPack;
	
	myTCPPack = (tcp_pack*)(myMsg.payload);
	myTCPPack->srcPort = fd.dest.port;
	myTCPPack->destPort = fd.src.port;

	//dbg(TRANSPORT_CHANNEL, "FIRING %hhu\n", fd.state);
	if(fd.state == ESTABLISHED) {
		myTCPPack->flag = FIN_FLAG;
		
		fd.state = FIN_WAIT;
		activeSockets[fd.fd] = fd;

		call Transport.makePack(&myMsg, TOS_NODE_ID, fd.dest.addr, 20, PROTOCOL_TCP, 0, myTCPPack, PACKET_MAX_PAYLOAD_SIZE);

		dbg(TRANSPORT_CHANNEL, "FIN WAIT...\n");

		call Sender.send(myMsg, (call RoutingTable.get(fd.dest.addr)));
	}else if(fd.state == FIN_WAIT) {
		myTCPPack->flag = FIN_ACK_FLAG;
		
		fd.state = TIME_WAIT;		
		activeSockets[fd.fd] = fd;
		call Transport.makePack(&myMsg, TOS_NODE_ID, fd.dest.addr, 20, PROTOCOL_TCP, 0, myTCPPack, PACKET_MAX_PAYLOAD_SIZE);

		call Sender.send(myMsg, (call RoutingTable.get(fd.dest.addr)));
	
		dbg(TRANSPORT_CHANNEL, "TIME WAIT...\n");

		call TimeWait.startOneShot(100000);

	}else if(fd.state == TIME_WAIT) {
		uint8_t i = 1;
		dbg(TRANSPORT_CHANNEL, "CONNECTION CLOSED\n");
		while(fd.rcvdBuff[i] != 0) {
			dbg(TRANSPORT_CHANNEL, "DATA: %hhu \n", fd.rcvdBuff[i]);
			i++;
		}
		fd.state = CLOSED;
		activeSockets[fd.fd] = fd;
	}
   }
  command error_t Transport.receive(pack* msg){

		uint8_t srcPort = 0;
		uint8_t destPort = 0;
		uint8_t seq = 0;
		uint8_t lastAck = 0;
		uint8_t flag = 0;
		uint16_t bufflen = TCP_PACKET_MAX_PAYLOAD_SIZE;
		uint16_t i = 0;
		uint16_t j = 0;
		uint32_t key = 0;
		
		socket_t mySocket;
		socket_t connectedSocket; 
		tcp_pack* myMsg = (tcp_pack *)(msg->payload);


		pack myNewMsg;
		tcp_pack* myTCPPack;

		srcPort = myMsg->srcPort;
		destPort = myMsg->destPort;
		seq = myMsg->seq;
		lastAck = myMsg->ACK;
		flag = myMsg->flag;
		//dbg(TRANSPORT_CHANNEL, "TEST!!!!!!!: %d %d\n", srcPort, destPort);
		/*for (i = 0; i < maxSockets; i++){
			mySocket = activeSockets[i];
			dbg(TRANSPORT_CHANNEL, "ACTIVE SOCKET: %d\n",);
		}*/

		if(flag == SYN_FLAG || flag == SYN_ACK_FLAG || flag == ACK_FLAG){

			if(flag == SYN_FLAG){
				dbg(TRANSPORT_CHANNEL, "Received SYN! \n");
				for(i = 0; i < maxSockets; i++) {
				mySocket = activeSockets[i];
					if(mySocket.src.port == destPort && mySocket.state == LISTEN) {
						dbg(ROUTING_CHANNEL, "ATTEMPTING CONNECTION WITH CLIENT\n");
						break;
					}else if(i == maxSockets - 1) {
						dbg(TRANSPORT_CHANNEL, "CONNECTION FAILED, NO SOCKET W/ PORT %d\n", destPort);
						return FAIL;
					}
				
				}
				
					if(mySocket.state == LISTEN){
						mySocket.state = SYN_RCVD;
						mySocket.dest.port = srcPort;
						mySocket.dest.addr = msg->src;
						
						activeSockets[mySocket.fd] = mySocket;
						myTCPPack = (tcp_pack *)(myNewMsg.payload);
						myTCPPack->destPort = mySocket.dest.port;
						myTCPPack->srcPort = mySocket.src.port;
						myTCPPack->seq = 1;
						myTCPPack->ACK = seq + 1;
						myTCPPack->flag = SYN_ACK_FLAG;
						dbg(TRANSPORT_CHANNEL, "Sending SYN ACK! %d\n", mySocket.state);
						call Transport.makePack(&myNewMsg, TOS_NODE_ID, mySocket.dest.addr, 20, 4, 0, myTCPPack, PACKET_MAX_PAYLOAD_SIZE);
						call Sender.send(myNewMsg, (call RoutingTable.get(mySocket.dest.addr)));
				}
			}
			
			else if(flag == SYN_ACK_FLAG){
				dbg(TRANSPORT_CHANNEL, "Received SYN ACK! \n");
				mySocket = getSocket(destPort, srcPort);
				mySocket.state = ESTABLISHED;
				//dbg(TRANSPORT_CHANNEL, "state: %d", mySocket.fd);
				activeSockets[mySocket.fd] = mySocket;
				myTCPPack = (tcp_pack*)(myNewMsg.payload);
				myTCPPack->destPort = mySocket.dest.port;
				myTCPPack->srcPort = mySocket.src.port;
				myTCPPack->seq = 1;
				myTCPPack->ACK = seq + 1;
				myTCPPack->flag = ACK_FLAG;
				dbg(TRANSPORT_CHANNEL, "SENDING ACK \n");
				call Transport.makePack(&myNewMsg, TOS_NODE_ID, mySocket.dest.addr, 20, 4, 0, myTCPPack, PACKET_MAX_PAYLOAD_SIZE);
				call Sender.send(myNewMsg, (call RoutingTable.get(mySocket.dest.addr)));
				dbg(TRANSPORT_CHANNEL, "CONNECTION ESTABLISHED! \n");
				connectFinish(mySocket);
			}

			else if(flag == ACK_FLAG){
				dbg(TRANSPORT_CHANNEL, "GOT ACK \n");
				mySocket = getSocket(destPort, srcPort);
				mySocket.state = ESTABLISHED;
					
				activeSockets[mySocket.fd] = mySocket;
				
			}
		}else if(flag == DATA_FLAG || flag == DATA_ACK_FLAG) {
			if(flag == DATA_FLAG) {
				dbg(TRANSPORT_CHANNEL, "RECEIVED DATA %u\n", myMsg->payload[0]);
				mySocket = getSocket(destPort, srcPort);
				myTCPPack = (tcp_pack*)(myNewMsg.payload);
				if(mySocket.state == ESTABLISHED) {
					//dbg(TRANSPORT_CHANNEL, "HERE\n");
					mySocket.lastRcvd = myMsg->payload[0];
					call RcvdPacketQueue.pushback(*msg);
					call ServerReadTimer.startOneShot(10);
					call SendTimer.startOneShot(10);
				}	
				activeSockets[mySocket.fd] = mySocket;		
			}else if(flag == DATA_ACK_FLAG) {
				dbg(TRANSPORT_CHANNEL, "RECEIVED DATA ACK %hhu %hhu\n", lastAck, seq);
				mySocket = getSocket(destPort, srcPort);
				myTCPPack = (tcp_pack*)(myNewMsg.payload);
				//dbg(TRANSPORT_CHANNEL, "Transfer %hhu\n", mySocket.transfer);
				if(seq == lastAck){
					mySocket.lastAck = lastAck;
					activeSockets[mySocket.fd] = mySocket;
					call SendPacketQueue.popfront();
					//call TimeoutTimer.startOneShot(500000);
					call SendTimer.startOneShot(10);
				
				//}else{
				//	call SendTimer.startOneShot(10);	
				}
				
				if(lastAck == 10) {
					//mySocket = activeSockets[1];
					dbg(TRANSPORT_CHANNEL, "CLIENT INITIATING TEARDOWN... \n");
					call Transport.close(mySocket);
				}
			}
		}else if(flag == FIN_FLAG || flag == FIN_ACK_FLAG){
			//mySocket = getSocket(destPort, srcPort);
			if(flag == FIN_FLAG) {
				mySocket = getSocket(srcPort, destPort);
				myTCPPack = (tcp_pack*)(myNewMsg.payload);
				dbg(TRANSPORT_CHANNEL, "RECEIVED FIN\n");
				call Transport.close(mySocket);
			}else if(flag == FIN_ACK_FLAG) {
				mySocket = getSocket(srcPort, destPort);
				dbg(TRANSPORT_CHANNEL, "RECEIVED FIN ACK\n");
				call Transport.close(mySocket);
			}
		}
	}
     
	/**
    * Read from the socket and write this data to the buffer. This data
    * is obtained from your TCP implimentation.
    * @param
    *    socket_t fd: file descriptor that is associated with the socket
    *       that is attempting a read.
    * @param
    *    uint8_t *buff: the buffer that is being written.
    * @param
    *    uint16_t bufflen: the amount of data that can be written to the
    *       buffer.
    * @Side For your project, only server side. This could be both though.
    * @return uint16_t - return the amount of data you are able to read
    *    from the pass buffer. This may be shorter then bufflen
    */
  
  
   command error_t Transport.release(socket_fd_t fd){
    /**
    * Listen to the socket and wait for a connection.
    * @param
    *    socket_t fd: file descriptor that is associated with the socket
    *       that you are hard closing.
    * @side Server
    * @return error_t - returns SUCCESS if you are able change the state
    *   to listen else FAIL.
    */
   }
   command error_t Transport.listen(socket_fd_t fd){
   
   }

   command void Transport.setTestServer(){
	socket_t mySocket;
	socket_addr_t myAddr;

	socket_fd_t fd = call Transport.socket();

	myAddr.addr = TOS_NODE_ID;
	myAddr.port = 2;
	
	//call Transport.bind(fd, &myAddr);
	mySocket.fd = fd;
	
	mySocket.src = myAddr;
	mySocket.state = LISTEN;

	mySocket.lastRcvd = 0;	
	mySocket.lastRead = 0;

	activeSockets[fd] = mySocket;
	call Transport.accept(mySocket);
	
	dbg(ROUTING_CHANNEL, "CREATING SERVER AT %d ON PORT %d\n", mySocket.src.addr, mySocket.src.port);
}

   command void Transport.setTestClient() {
	socket_t mySocket;
	socket_fd_t fd;
	socket_addr_t myAddr;
	socket_addr_t serverAddr;
	uint8_t i = 0;

	fd = call Transport.socket();

	myAddr.addr = TOS_NODE_ID;
	myAddr.port = 3;

	//bind
	mySocket.fd = fd;

	serverAddr.addr = 1;
	serverAddr.port = 2;

	mySocket.src = myAddr;
	mySocket.dest = serverAddr;

	mySocket.transfer = 10;
	mySocket.lastWritten = 0;
	for(i = 0; i < SOCKET_BUFFER_SIZE; i++) {
		mySocket.sendBuff[i] = 0;
	}

	activeSockets[fd] = mySocket;
	dbg(ROUTING_CHANNEL, "CREATING CLIENT AT %d ON PORT %d\n", mySocket.src.addr, mySocket.src.port);

	call Transport.connect(mySocket);
	
}
	
   event void ClientWriteTimer.fired(){
	uint8_t i = 0;
	socket_t mySocket;
	//dbg(TRANSPORT_CHANNEL, "FIRING\n");
	//Search for correct socket
	for(i = 0; i < maxSockets; i++) {
		mySocket = activeSockets[i];
		if(mySocket.src.addr == TOS_NODE_ID) {
			break;
		}else if(i == maxSockets - 1) {
			//dbg(TRANSPORT_CHANNEL, "COULD NOT LOCATE SOCKET\n");
			return;
		}
	}
	//if sendBuff empty, fill with data
	if(mySocket.sendBuff[mySocket.transfer] == 0){
		for(i = 0; i < mySocket.transfer && i < SOCKET_BUFFER_SIZE; i++) {
			mySocket.sendBuff[i] = i + 1;
		}
	}
	//call clientWrite and update transfer index
	//uint8_t* buff = (uint8_t*)mySocket.sendBuff;
	mySocket.lastWritten =  mySocket.lastWritten + (call Transport.write(mySocket, mySocket.sendBuff, SOCKET_BUFFER_SIZE));
	mySocket.transfer = mySocket.transfer - mySocket.lastWritten;

	if(mySocket.transfer == 0) {
		call ClientWriteTimer.stop();
	} 
}

   event void SendTimer.fired() {
	pack myMsg;
	
	if(!(call SendPacketQueue.isEmpty())) {
		myMsg = call SendPacketQueue.front();
		call Sender.send(myMsg, (call RoutingTable.get(myMsg.dest)));
		call TimeoutTimer.startOneShot(5000);
	}
}
   event void ServerReadTimer.fired(){
	pack myMsg;
	tcp_pack* myTCPPack;
	socket_t mySocket;
	//dbg(TRANSPORT_CHANNEL, "empty: %d\n", !(call RcvdPacketQueue.isEmpty()));
	if(!(call RcvdPacketQueue.isEmpty())) {
		//dbg(TRANSPORT_CHANNEL, "HERE\n");
		myMsg = (call RcvdPacketQueue.popfront());
		myTCPPack = (tcp_pack *)(myMsg.payload);

		mySocket = getSocket(myTCPPack->destPort, myTCPPack->srcPort);
	
		mySocket.lastRead = mySocket.lastRead + (call Transport.read(mySocket, mySocket.rcvdBuff, SOCKET_BUFFER_SIZE));
		activeSockets[mySocket.fd] = mySocket;
	}

	if(mySocket.lastRead == mySocket.transfer) {
		myTCPPack->flag = FIN_FLAG;
		dbg(TRANSPORT_CHANNEL, "CLIENT INITIATING TEARDOWN...\n");
		call Transport.makePack(&myMsg, TOS_NODE_ID, mySocket.dest.addr, 20, PROTOCOL_TCP, 0, myTCPPack, PACKET_MAX_PAYLOAD_SIZE);
		call Sender.send(myMsg, mySocket.dest.addr);	
	}		
}

   event void TimeWait.fired() {
	socket_t mySocket;
	uint8_t i = 0;
	
	for(i = 0; i < maxSockets; i++){
		mySocket = activeSockets[i];
		if(mySocket.state == TIME_WAIT) {
			call Transport.close(mySocket);
		}
	}
}

   event void TimeoutTimer.fired() {
	pack myMsg;
	socket_t mySocket;
	tcp_pack* myTCPPack;
	dbg(TRANSPORT_CHANNEL, "TIMEOUT\n");
	if(!(call SendPacketQueue.isEmpty())) {
		myMsg = call SendPacketQueue.front();
		myTCPPack = (tcp_pack *)(myMsg.payload);
		mySocket = getSocket(myTCPPack->srcPort, myTCPPack->destPort);
		if(myTCPPack->seq != mySocket.lastAck) {
			dbg(TRANSPORT_CHANNEL, "RETRANSMITTING %d\n", myTCPPack->seq);
			call Sender.send(myMsg, (call RoutingTable.get(myMsg.dest)));
		}
	}else{
		call TimeoutTimer.stop();
	}
}
   command void Transport.makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      Package->seq = seq;
      Package->protocol = protocol;
      memcpy(Package->payload, payload, length);
   }
   
}
