import 'package:flutterapp/ReceivedMessage.dart';

class ArrayMessage extends ReceivedMessage{
  String message;

  ArrayMessage(this.message) {
    this.messageType = "Array";
  }


}