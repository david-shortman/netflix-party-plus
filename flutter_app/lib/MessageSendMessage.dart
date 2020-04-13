import 'package:flutterapp/Message.dart';
import 'package:flutterapp/UserMessage.dart';

class SendMessageMessage extends Message {
  UserMessage userMessage;

  SendMessageMessage(Map<String, dynamic> objectFromMessage) {
    userMessage = new UserMessage(objectFromMessage);
  }


}