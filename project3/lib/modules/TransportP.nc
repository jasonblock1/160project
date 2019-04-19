#include "../../includes/socket.h"
#include "../../includes/packet.h"
#include "../../includes/TCPPacket.h"
#include "../../includes/protocol.h"

module TransportP{
   provides interface Transport;

   uses interface Random as Random;
   uses interface SimpleSend as Sender;
   uses interface List<socket_t> as SocketList;
   uses interface List<pack> as SendPacketQueue;
   uses interface List<pack> as RcvdPacketQueue;
   uses interface Timer<TMilli> as ServerReadTimer;
   uses interface Timer<TMilli> as ClientWriteTimer;
   uses interface Timer<TMilli> as SendTimer;
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
	
		myTCPPack = (tcp_pack*)(myMsg.payload);
		myTCPPack->destPort = mySocket.dest.port;
		myTCPPack->srcPort = mySocket.src.port;
		myTCPPack->seq = 0;
		myTCPPack->flag = DATA_FLAG;

		call ClientWriteTimer.startPeriodic(100);
		call SendTimer.startOneShot(1000);
		call ServerReadTimer.startPeriodic(100);
		//myMsg = call packetQueue.popfront()
		/*while(i < 1 //TCP_PACKET_MAX_PAYLOAD_SIZE) {
			myTCPPack->payload[i] = i;
			dbg(TRANSPORT_CHANNEL, "SENDING DATA...%u \n", myTCPPack->payload[i]);
			i++;
		}
		
		myTCPPack->seq = i;
		call Transport.makePack(&myMsg, TOS_NODE_ID, mySocket.dest.addr, 20, PROTOCOL_TCP, 0, myTCPPack, PACKET_MAX_PAYLOAD_SIZE);
		
		call packetQueue.enqueue(myMsg);
		dbg(TRANSPORT_CHANNEL, "SENDING DATA...%d \n", mySocket.dest.addr);
		call Sender.send(myMsg, mySocket.dest.addr);
		*/		
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
	/*uint32_t size = call SocketList.size();
	uint32_t i = 0;
	socket_t mySocket;

	for (i = 0; i < size; i++) {
		mySocket = call SocketList.get(i);
		if (mySocket.fd == 0) {
			mySocket.fd = fd;
		}
	}*/
	
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
	uint16_t size = call SocketList.size();
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
	
	for(i = fd.lastWritten; i < fd.transfer && i < bufflen; i++) {
		if(call SendPacketQueue.size() < 20) {
			myTCPPack->payload[0] = buff[i];
			myTCPPack->seq = i;
			//dbg(TRANSPORT_CHANNEL, "%hu\n", buff[i]);
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
	dbg(TRANSPORT_CHANNEL, "READING DATA: ");
	for(i = fd.lastRead;  i < bufflen; i++) {
		if(!(call RcvdPacketQueue.isEmpty())) {
			myTCPPack->payload[0] = buff[i];
			myTCPPack->ACK = i;
			myTCPPack->flag = DATA_ACK_FLAG;
			dbg(TRANSPORT_CHANNEL, "%hu ", buff[i]);
			call Transport.makePack(&myMsg, TOS_NODE_ID, fd.dest.addr, 20, PROTOCOL_TCP, 0, myTCPPack, PACKET_MAX_PAYLOAD_SIZE);
		
			call SendPacketQueue.pushback(myMsg);
			bytesRead++;
		}else {
			return bytesRead;
		}
	}

	dbg(TRANSPORT_CHANNEL, "\n");
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

	myTCPpack = (tcp_pack*)(myMsg.payload);
	myTCPpack->srcPort = mySocket.src.port;
	myTCPpack->destPort = mySocket.dest.port;
	myTCPpack->flag = SYN_FLAG;
	myTCPpack->seq = 1;

	call Transport.makePack(&myMsg, TOS_NODE_ID, mySocket.dest.addr, 20, PROTOCOL_TCP, 0, myTCPpack, PACKET_MAX_PAYLOAD_SIZE);
	mySocket.state = SYN_SENT;

	dbg(TRANSPORT_CHANNEL, "CLIENT CONNECTING...\n");

	call Sender.send(myMsg, mySocket.dest.addr);

	
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
   command error_t Transport.close(socket_fd_t fd){
      /**
    * A hard close, which is not graceful. This portion is optional.
    * @param
    *    socket_t fd: file descriptor that is associated with the socket
    *       that you are hard closing.
    * @side Client/Server
    * @return socket_t - returns SUCCESS if you are able to attempt
    *    a closure with the fd passed, else return FAIL.
    */
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
		tcp_pack* myMsg = (tcp_pack *)(msg->payload);


		pack myNewMsg;
		tcp_pack* myTCPPack;

		srcPort = myMsg->srcPort;
		destPort = myMsg->destPort;
		seq = myMsg->seq;
		lastAck = myMsg->ACK;
		flag = myMsg->flag;

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
						dbg(TRANSPORT_CHANNEL, "Sending SYN ACK! %d\n", mySocket.src.port);
						call Transport.makePack(&myNewMsg, TOS_NODE_ID, mySocket.dest.addr, 20, 4, 0, myTCPPack, PACKET_MAX_PAYLOAD_SIZE);
						call Sender.send(myNewMsg, mySocket.dest.addr);
				}
			}
			
			else if(flag == SYN_ACK_FLAG){
				dbg(TRANSPORT_CHANNEL, "Received SYN ACK! \n");
				mySocket = getSocket(destPort, srcPort);
				mySocket.state = ESTABLISHED;
				
				activeSockets[mySocket.fd] = mySocket;
				myTCPPack = (tcp_pack*)(myNewMsg.payload);
				myTCPPack->destPort = mySocket.dest.port;
				myTCPPack->srcPort = mySocket.src.port;
				myTCPPack->seq = 1;
				myTCPPack->ACK = seq + 1;
				myTCPPack->flag = ACK_FLAG;
				dbg(TRANSPORT_CHANNEL, "SENDING ACK \n");
				call Transport.makePack(&myNewMsg, TOS_NODE_ID, mySocket.dest.addr, 20, 4, 0, myTCPPack, PACKET_MAX_PAYLOAD_SIZE);
				call Sender.send(myNewMsg, mySocket.dest.addr);
				dbg(TRANSPORT_CHANNEL, "CONNECTION ESTABLISHED! \n");
				connectFinish(mySocket);
			}

			else if(flag == ACK_FLAG){
				dbg(TRANSPORT_CHANNEL, "GOT ACK \n");
				mySocket = getSocket(destPort, srcPort);
				if(mySocket.state == SYN_RCVD){
					mySocket.state = ESTABLISHED;
					
					activeSockets[mySocket.fd] = mySocket;
				}
			}
		}else if(flag == DATA_FLAG || flag == DATA_ACK_FLAG) {
			
			if(flag == DATA_FLAG) {
				dbg(TRANSPORT_CHANNEL, "RECEIVED DATA %u\n", myMsg->payload[0]);
				mySocket = getSocket(destPort, srcPort);
				myTCPPack = (tcp_pack*)(myNewMsg.payload);
				//dbg(TRANSPORT_CHANNEL, "SOCKET STATE %d\n", mySocket.state);
				if(mySocket.state == ESTABLISHED) {
					mySocket.lastRcvd = myMsg->payload[0];
					call RcvdPacketQueue.pushback(myMsg);
					//call ServerReadTimer.()
					/*myTCPPack = (tcp_pack*)(myNewMsg.payload);
					if(myMsg->payload[0] != 0) {
						j = 0;
						i = mySocket.lastRcvd + 1;
						while(j < myMsg->seq){
							mySocket.rcvdBuff[i] = myMsg->payload[j];
							mySocket.lastRcvd = myMsg->payload[j];
							//dbg(TRANSPORT_CHANNEL,"DATA: %d\n", myMsg->payload[j]);
							i++;
							j++;
						}
					}else{
						i = 0;
						while(i < myMsg->seq){
							mySocket.rcvdBuff[i] = myMsg->payload[i];
							mySocket.lastRcvd = myMsg->payload[i];
							dbg(TRANSPORT_CHANNEL,"DATA: %d\n", myMsg->payload[i]);
							i++;
						}
					}
				mySocket.effectiveWindow = SOCKET_BUFFER_SIZE - mySocket.lastRcvd + 1;
				dbg(TRANSPORT_CHANNEL, "seq %d\n", myMsg->seq);
				
				activeSockets[mySocket.fd] = mySocket;
				*/
				}			
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
	mySocket.lastWritten = 0;

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
			dbg(TRANSPORT_CHANNEL, "COULD NOT LOCATE SOCKET\n");
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
	/*socket_t mySocket;
	pack myMsg;
	uint8_t i = 0;
	for(i = 0; i < maxSockets; i++) {
		mySocket = activeSockets[i];
		if(mySocket.src.addr == TOS_NODE_ID) {
			break;
		}else if(i == maxSockets - 1) {
			dbg(TRANSPORT_CHANNEL, "COULD NOT LOCATE SOCKET\n");
			return;
		}
	}*/
	
	myMsg = call SendPacketQueue.popfront();
	call Sender.send(myMsg, myMsg.dest);
}
   event void ServerReadTimer.fired(){
	pack myMsg;
	tcp_pack* myTCPPack;
	socket_t mySocket;
	
	myMsg = (call RcvdPacketQueue.popfront());
	myTCPPack = (tcp_pack *)(myMsg->payload);

	mySocket = getSocket(myTCPPack->destPort, myTCPPack->srcPort);

	mySocket.lastRead = mySocket.lastRead + (call Transport.read(mySocket, mySocket.rcvdBuff, SOCKET_BUFFER_SIZE));		
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
