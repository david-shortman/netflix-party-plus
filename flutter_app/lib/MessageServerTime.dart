import 'package:flutterapp/ReceivedMessage.dart';

class ServerTimeMessage extends ReceivedMessage{
  int serverTime = 0;

  ServerTimeMessage(this.serverTime) {
    this.messageType = "ServerTime";
  }

}