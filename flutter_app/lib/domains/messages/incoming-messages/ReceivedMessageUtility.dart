import 'package:flutter/cupertino.dart';
import 'package:flutterapp/domains/messages/incoming-messages/ReceivedMessage.dart';
import 'package:flutterapp/domains/messages/incoming-messages/MessageSendMessage.dart';
import 'package:flutterapp/domains/messages/incoming-messages/MessageServerTime.dart';
import 'package:flutterapp/domains/messages/incoming-messages/MessageSid.dart';
import 'package:flutterapp/domains/messages/incoming-messages/MessageUserId.dart';
import 'package:flutterapp/domains/messages/Message.dart';

import 'MessageUpdate.dart';
import 'MessageVideoIdAndMessageBacklog.dart';

class ReceivedMessageUtility {
  static ReceivedMessage fromString(String message) {
    SocketMessage socketMessage = new SocketMessage.fromString(message);

    debugPrint('received: ${socketMessage.buildString(0)}');

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
          if (messageContentMap.containsKey('videoId')) {
            return new VideoIdAndMessageCatchupMessage(messageContentMap['value']);
          }
        }
    }

    debugPrint('Not implemented: ${socketMessage.buildString(0)}\n');
    return new ReceivedMessage();
    }
}