import 'package:flutterapp/domains/messages/incoming-messages/ReceivedMessage.dart';

class ObjectMessage extends ReceivedMessage {
  String message;

  ObjectMessage(this.message) {
    this.messageType = "Object";
  }


}