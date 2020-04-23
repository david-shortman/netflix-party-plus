import 'package:np_plus/domains/messages/incoming-messages/ReceivedMessage.dart';

class ArrayMessage extends ReceivedMessage {
  String message;

  ArrayMessage(this.message) {
    this.messageType = "Array";
  }
}
