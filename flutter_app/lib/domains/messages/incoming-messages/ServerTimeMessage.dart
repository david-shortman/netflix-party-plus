import 'package:np_plus/domains/messages/incoming-messages/ReceivedMessage.dart';

class ServerTimeMessage extends ReceivedMessage {
  int serverTime = 0;

  ServerTimeMessage(this.serverTime) {
    this.messageType = "ServerTime";
  }
}
