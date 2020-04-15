import 'dart:convert';

import 'package:flutter/cupertino.dart';

class UserMessage {
  String body;
  bool isSystemMessage;
  int timestamp;
  String userId;
  String permId;
  String userIcon;
  String userNickname;

  UserMessage(Map<String, dynamic> objectFromMessage) {
    body = objectFromMessage['body'];
    isSystemMessage = objectFromMessage['isSystemMessage'];
    timestamp = objectFromMessage['timestamp'];
    userId = objectFromMessage['userId'];
    permId = objectFromMessage['permId'];
    userIcon = objectFromMessage['userIcon'];
    userNickname = objectFromMessage['userNickname'];
    debugPrint('\n !!!! ' + json.encode(objectFromMessage));
  }
}