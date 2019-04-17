#include "../../includes/socket.h"

configuration TransportC{
   provides interface Transport;
}

implementation{
    components TransportP;
    Transport = TransportP;

    components 	RandomC as Random;
    TransportP.Random -> Random;

    components new SimpleSendC(AM_PACK);
    TransportP.Sender -> SimpleSendC;
	
    components new TimerMilliC() as ServerTimerC;
    TransportP.ServerTimer -> ServerTimerC; 

    components new ListC(socket_t, 10) as SocketListC;
    TransportP.SocketList -> SocketListC;
}
