import 'package:flutterapp/Message.dart';

class ServerTimeMessage extends Message{
  int serverTime = 0;

  ServerTimeMessage(this.serverTime) {
    this.messageType = "ServerTime";
  }

}