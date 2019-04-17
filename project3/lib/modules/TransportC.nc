#include "../../includes/socket.h"

configuration TransportC{
   provides interface Transport;
}

implementation{
    components TransportP;
    Transport = TransportP;

    components 	RandomC as Random;
    TransportP.Random -> Random;
}
