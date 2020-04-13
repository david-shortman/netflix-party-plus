import 'package:flutterapp/Message.dart';

class ObjectMessage extends Message {
  String message;

  ObjectMessage(this.message) {
    this.messageType = "Object";
  }


}