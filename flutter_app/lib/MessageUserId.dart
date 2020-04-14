import 'package:flutterapp/ReceivedMessage.dart';

class UserIdMessage extends ReceivedMessage {
  String userId;

  UserIdMessage(this.userId) {
    this.messageType = "UserId";
  }


}