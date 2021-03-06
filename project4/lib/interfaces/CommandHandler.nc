interface CommandHandler{
   // Events
   event void ping(uint16_t destination, uint8_t *payload);
   event void printNeighbors();
   event void printRouteTable();
   event void printLinkState();
   event void printDistanceVector();
   event void setTestServer();
   event void setTestClient();
   event void setAppServer();
   event void setAppClient();
   event void setChatServer();
   event void hello(uint8_t *msg);
   event void msg(uint8_t *msg);
   event void whisper(uint8_t *msg);
   event void printUsers(uint8_t *msg);
}
