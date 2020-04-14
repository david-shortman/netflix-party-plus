import 'package:flutterapp/ReceivedMessage.dart';

class ObjectMessage extends ReceivedMessage {
  String message;

  ObjectMessage(this.message) {
    this.messageType = "Object";
  }


}