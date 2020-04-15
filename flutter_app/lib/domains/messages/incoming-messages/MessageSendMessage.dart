import 'package:flutterapp/domains/messages/incoming-messages/ReceivedMessage.dart';
import 'package:flutterapp/domains/messages/incoming-messages/UserMessage.dart';

class SentMessageMessage extends ReceivedMessage {
  UserMessage userMessage;

  SentMessageMessage(Map<String, dynamic> objectFromMessage) {
    userMessage = new UserMessage(objectFromMessage);
  }


}