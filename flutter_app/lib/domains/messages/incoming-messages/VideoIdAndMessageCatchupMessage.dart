import 'package:np_plus/domains/messages/incoming-messages/ReceivedMessage.dart';
import 'package:np_plus/domains/messages/incoming-messages/UserMessage.dart';

class VideoIdAndMessageCatchupMessage extends ReceivedMessage {
  int videoId;
  int lastKnownTime;
  int lastKnownTimeUpdatedAt;
  String state;
  List<UserMessage> userMessages;

  VideoIdAndMessageCatchupMessage(Map<String, dynamic> objectFromMessage) {
    videoId = objectFromMessage['videoId'];
    var messageArray = objectFromMessage['messages'] as List<dynamic>;
    userMessages = List<UserMessage>();
    state = objectFromMessage['state'];
    lastKnownTime = objectFromMessage['lastKnownTime'];
    lastKnownTimeUpdatedAt = objectFromMessage['lastKnownTimeUpdatedAt'];
    Iterator<dynamic> messageIterator = messageArray.iterator;
    while (messageIterator.moveNext()) {
      userMessages.add(UserMessage(messageIterator.current));
    }
  }
}
