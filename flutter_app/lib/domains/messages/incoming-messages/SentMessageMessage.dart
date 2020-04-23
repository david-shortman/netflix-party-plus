import 'package:np_plus/domains/messages/incoming-messages/ReceivedMessage.dart';
import 'package:np_plus/domains/messages/incoming-messages/UserMessage.dart';

class SentMessageMessage extends ReceivedMessage {
  UserMessage userMessage;

  SentMessageMessage(Map<String, dynamic> objectFromMessage) {
    userMessage = UserMessage(objectFromMessage);
  }
}
