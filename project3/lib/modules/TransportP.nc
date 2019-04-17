#include "../../includes/socket.h"
#include "../../includes/packet.h"
#include "../../includes/TCPPacket.h"
#include "../../includes/protocol.h"

module TransportP{
   provides interface Transport;

   uses interface Random as Random;
   uses interface SimpleSend as Sender;
   uses interface List<socket_t> as SocketList;
   uses interface Timer<TMilli> as ServerTimer;
}

implementation{
   uint8_t socketIndex = 1;
   socket_t getSocket(uint8_t destPort, uint8_t srcPort);

	socket_t getSocket(uint8_t destPort, uint8_t srcPort){
		socket_t mySocket;
		uint32_t i = 0;
		uint32_t size = call SocketList.size();
		
		for (i = 0; i < size; i++){
			mySocket = call SocketList.get(i);
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
	//dbg(ROUTING_CHANNEL, "CLIENT FOUND\n");
	for(i = 0; i < size; i++) {
		mySocket = call SocketList.get(i);
		if(mySocket.dest.port == server.src.port && server.state == LISTEN) {
			dbg(ROUTING_CHANNEL, "CLIENT FOUND\n");
			server.dest.addr = mySocket.src.addr;
			server.dest.port = mySocket.src.port;
			return server;
		}
	}

	return server;
	
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

  command uint16_t Transport.write(socket_fd_t fd, uint8_t *buff, uint16_t bufflen){
   /**
    * This will pass the packet so you can handle it internally.
    * @param
    *    pack *package: the TCP packet that you are handling.
    * @Side Client/Server
    * @return uint16_t - return SUCCESS if you are able to handle this
    *    packet or FAIL if there are errors.
    */

  }
  
  command uint16_t Transport.read(socket_fd_t fd, uint8_t *buff, uint16_t bufflen){
  
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
		uint8_t size = call SocketList.size();
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
				dbg(TRANSPORT_CHANNEL, "Got SYN! \n");
				for(i = 0; i < size; i++) {
				mySocket = call SocketList.get(i);
					if(mySocket.src.port == destPort && mySocket.state == LISTEN) {
						dbg(ROUTING_CHANNEL, "ATTEMPTING CONNECTION WITH CLIENT\n");
						continue;
					}
				}
				
					if(mySocket.state == LISTEN){
					mySocket.state = SYN_RCVD;
					mySocket.dest.port = srcPort;
					mySocket.dest.addr = msg->src;
					call SocketList.pushback(mySocket);
				
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
				dbg(TRANSPORT_CHANNEL, "Got SYN ACK! \n");
				mySocket = getSocket(destPort, srcPort);
				mySocket.state = ESTABLISHED;
				call SocketList.pushback(mySocket);

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
				//connectDone(mySocket);
			}

			else if(flag == ACK_FLAG){
				dbg(TRANSPORT_CHANNEL, "GOT ACK \n");
				mySocket = getSocket(destPort, srcPort);
				if(mySocket.state == SYN_RCVD){
					mySocket.state = ESTABLISHED;
					call SocketList.pushback(mySocket);
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

	call SocketList.pushback(mySocket);

	call Transport.accept(mySocket);
	
	dbg(ROUTING_CHANNEL, "CREATING SERVER AT %d ON PORT %d\n", mySocket.src.addr, mySocket.src.port);
}

   command void Transport.setTestClient() {
	socket_t mySocket;
	socket_fd_t fd;
	socket_addr_t myAddr;
	socket_addr_t serverAddr;

	fd = call Transport.socket();

	myAddr.addr = TOS_NODE_ID;
	myAddr.port = 3;

	//bind
	mySocket.fd = fd;

	serverAddr.addr = 1;
	serverAddr.port = 2;

	mySocket.src = myAddr;
	mySocket.dest = serverAddr;

	call SocketList.pushback(mySocket);
	
	dbg(ROUTING_CHANNEL, "CREATING CLIENT AT %d ON PORT %d\n", mySocket.src.addr, mySocket.src.port);

	call Transport.connect(mySocket);
	
}

   event void ServerTimer.fired(){}

   command void Transport.makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      Package->seq = seq;
      Package->protocol = protocol;
      memcpy(Package->payload, payload, length);
   }
   
}
