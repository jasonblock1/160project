#include "../../includes/socket.h"
#include "../../includes/packet.h"
#include <Timer.h>
configuration TransportC{
   provides interface Transport;
}

implementation{
    components TransportP;
    Transport = TransportP;

    components 	RandomC as Random;
    TransportP.Random -> Random;

    components RoutingTableC;
    TransportP.RoutingTable -> RoutingTableC;

    components new SimpleSendC(AM_PACK);
    TransportP.Sender -> SimpleSendC;
	
    components new TimerMilliC() as ServerReadTimerC;
    TransportP.ServerReadTimer -> ServerReadTimerC; 

    components new TimerMilliC() as ClientWriteTimerC;
    TransportP.ClientWriteTimer -> ClientWriteTimerC;

    components new TimerMilliC() as SendTimerC;
    TransportP.SendTimer -> SendTimerC;

    components new TimerMilliC() as TimeoutTimerC;
    TransportP.TimeoutTimer -> TimeoutTimerC;

    components new TimerMilliC() as TimeWaitC;
    TransportP.TimeWait -> TimeWaitC;

    components new ListC(socket_t, 10) as SocketListC;
    TransportP.SocketList -> SocketListC;

    components new ListC(pack, 100) as SendPacketQueueC;
    TransportP.SendPacketQueue -> SendPacketQueueC;

    components new ListC(pack, 100) as RcvdPacketQueueC;
    TransportP.RcvdPacketQueue -> RcvdPacketQueueC;
}
