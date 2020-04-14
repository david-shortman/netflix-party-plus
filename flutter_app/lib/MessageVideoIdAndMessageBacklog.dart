import 'package:flutterapp/ReceivedMessage.dart';
import 'package:flutterapp/UserMessage.dart';

class VideoIdAndMessageCatchupMessage extends ReceivedMessage {
  int videoId;
  int lastKnownTime;
  int lastKnownTimeUpdatedAt;
  String state;
  List<UserMessage> userMessages;

  VideoIdAndMessageCatchupMessage(Map<String, dynamic> objectFromMessage) {
    videoId = objectFromMessage['videoId'];
    var messageArray = objectFromMessage['messages'] as List<dynamic>;
    userMessages = new List<UserMessage>();
    state = objectFromMessage['state'];
    lastKnownTime = objectFromMessage['lastKnownTime'];
    lastKnownTimeUpdatedAt = objectFromMessage['lastKnownTimeUpdatedAt'];
    Iterator<dynamic> messageIterator = messageArray.iterator;
    while(messageIterator.moveNext()) {
      userMessages.add(new UserMessage(messageIterator.current));
    }

  }


}