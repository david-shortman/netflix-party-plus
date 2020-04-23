import 'package:np_plus/domains/messages/incoming-messages/ReceivedMessage.dart';

class UserIdMessage extends ReceivedMessage {
  String userId;

  UserIdMessage(this.userId) {
    this.messageType = "UserId";
  }
}
