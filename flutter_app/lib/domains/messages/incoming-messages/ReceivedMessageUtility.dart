import 'package:flutter/cupertino.dart';
import 'package:np_plus/domains/messages/incoming-messages/ErrorMessage.dart';
import 'package:np_plus/domains/messages/incoming-messages/ReceivedMessage.dart';
import 'package:np_plus/domains/messages/incoming-messages/SentMessageMessage.dart';
import 'package:np_plus/domains/messages/incoming-messages/ServerTimeMessage.dart';
import 'package:np_plus/domains/messages/incoming-messages/SidMessage.dart';
import 'package:np_plus/domains/messages/incoming-messages/SetPresenceMessage.dart';
import 'package:np_plus/domains/messages/incoming-messages/UserIdMessage.dart';
import 'package:np_plus/domains/messages/SocketMessage.dart';

import 'UpdateMessage.dart';
import 'VideoIdAndMessageCatchupMessage.dart';

class ReceivedMessageUtility {
  static ReceivedMessage fromString(String message) {
    SocketMessage socketMessage = SocketMessage.fromString(message);

    Map<String, dynamic> messageContentMap = socketMessage.content.toMap();

    if (messageContentMap.containsKey('sid')) {
      return SidMessage(messageContentMap);
    }

    switch (socketMessage.type) {
      case "userId":
        return UserIdMessage(messageContentMap['value']);
      case "sendMessage":
        return SentMessageMessage(messageContentMap['value']);
      case "update":
        return UpdateMessage(messageContentMap['value']);
      case "setPresence":
        return SetPresenceMessage(messageContentMap['value']);
      case "unknown":
        if (messageContentMap['value'] is int) {
          return ServerTimeMessage(messageContentMap['value']);
        }
        if (messageContentMap['value'] is Map) {
          if (messageContentMap['value'].containsKey('videoId')) {
            return VideoIdAndMessageCatchupMessage(messageContentMap['value']);
          } else if (messageContentMap['value'].containsKey('errorMessage')) {
            return ErrorMessage(messageContentMap['value']);
          }
        }
    }

    debugPrint('Not implemented: ${socketMessage.buildString(0)}\n');
    return ReceivedMessage();
  }
}
