import 'package:flutterapp/ReceivedMessage.dart';
import 'package:flutterapp/UserMessage.dart';

class MessageSendMessage extends ReceivedMessage {
  UserMessage userMessage;

  MessageSendMessage(Map<String, dynamic> objectFromMessage) {
    userMessage = new UserMessage(objectFromMessage);
  }


}