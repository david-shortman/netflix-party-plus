import 'package:flutterapp/Message.dart';
import 'package:flutterapp/UserMessage.dart';

class MessageSendMessage extends Message {
  UserMessage userMessage;

  MessageSendMessage(Map<String, dynamic> objectFromMessage) {
    userMessage = new UserMessage(objectFromMessage);
  }


}