import 'ReceivedMessage.dart';

class UpdateMessage extends ReceivedMessage {
  int lastKnownTime;
  int lastKnownTimeRemaining;
  int lastKnownTimeUpdatedAt;
  String state;
  int videoDuration;

  UpdateMessage(Map<String, dynamic> objectFromMessage) {
    this.messageType = "Update";
    this.lastKnownTime = objectFromMessage['lastKnownTime'];
    this.lastKnownTimeRemaining = objectFromMessage['lastKnownTimeRemaining'];
    this.lastKnownTimeUpdatedAt = objectFromMessage['lastKnownTimeUpdatedAt'];
    this.state = objectFromMessage['state'];
    this.videoDuration = objectFromMessage['videoDuration'];
  }
}
