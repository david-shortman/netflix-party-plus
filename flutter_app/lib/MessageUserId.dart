import 'package:flutterapp/Message.dart';

class UserIdMessage extends Message {
  String userId;

  UserIdMessage(this.userId) {
    this.messageType = "UserId";
  }


}