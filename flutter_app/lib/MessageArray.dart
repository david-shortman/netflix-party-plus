import 'package:flutterapp/Message.dart';

class ArrayMessage extends Message{
  String message;

  ArrayMessage(this.message) {
    this.messageType = "Array";
  }


}