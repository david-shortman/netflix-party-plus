import 'package:flutter/cupertino.dart';
import 'package:flutterapp/domains/messages/incoming-messages/ErrorMessage.dart';
import 'package:flutterapp/domains/messages/incoming-messages/ReceivedMessage.dart';
import 'package:flutterapp/domains/messages/incoming-messages/SentMessageMessage.dart';
import 'package:flutterapp/domains/messages/incoming-messages/ServerTimeMessage.dart';
import 'package:flutterapp/domains/messages/incoming-messages/SidMessage.dart';
import 'package:flutterapp/domains/messages/incoming-messages/UserIdMessage.dart';
import 'package:flutterapp/domains/messages/SocketMessage.dart';

import 'UpdateMessage.dart';
import 'VideoIdAndMessageCatchupMessage.dart';

class ReceivedMessageUtility {
  static ReceivedMessage fromString(String message) {
    SocketMessage socketMessage = new SocketMessage.fromString(message);

    Map<String, dynamic> messageContentMap = socketMessage.content.toMap();

    if (messageContentMap.containsKey('sid')) {
      return new SidMessage(messageContentMap);
    }

    switch (socketMessage.type) {
      case "userId":
        return new UserIdMessage(messageContentMap['value']);
      case "sendMessage":
        return new SentMessageMessage(messageContentMap['value']);
      case "update":
        return new UpdateMessage(messageContentMap['value']);
      case "unknown":
        if (messageContentMap['value'] is int) {
          return new ServerTimeMessage(messageContentMap['value']);
        }
        if (messageContentMap['value'] is Map) {
          if (messageContentMap['value'].containsKey('videoId')) {
            return new VideoIdAndMessageCatchupMessage(
                messageContentMap['value']);
          } else if (messageContentMap['value'].containsKey('errorMessage')) {
            return new ErrorMessage(messageContentMap['value']);
          }
        }
    }

    debugPrint('Not implemented: ${socketMessage.buildString(0)}\n');
    return new ReceivedMessage();
  }
}
