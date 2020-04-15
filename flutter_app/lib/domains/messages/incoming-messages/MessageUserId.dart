import 'package:flutterapp/domains/messages/incoming-messages/ReceivedMessage.dart';

class UserIdMessage extends ReceivedMessage {
  String userId;

  UserIdMessage(this.userId) {
    this.messageType = "UserId";
  }


}