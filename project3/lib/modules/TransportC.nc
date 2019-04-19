#include "../../includes/socket.h"
#include "../../includes/packet.h"
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

    components new TimerMilliC() as ClientWriteTimerC;
    TransportP.ClientWriteTimer -> ClientWriteTimerC;

    components new TimerMilliC() as SendTimerC;
    TransportP.SendTimer -> SendTimerC;

    components new ListC(socket_t, 10) as SocketListC;
    TransportP.SocketList -> SocketListC;

    components new ListC(pack, 20) as SendPacketQueueC;
    TransportP.SendPacketQueue -> SendPacketQueueC;

    components new ListC(pack, 20) as RcvdPacketQueueC;
    TransportP.RcvdPacketQueue -> RcvdPacketQueueC;
}
