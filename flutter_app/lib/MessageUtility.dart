import 'package:flutter/cupertino.dart';
import 'package:flutterapp/ReceivedMessage.dart';
import 'package:flutterapp/MessageSendMessage.dart';
import 'package:flutterapp/MessageServerTime.dart';
import 'package:flutterapp/MessageSid.dart';
import 'package:flutterapp/MessageUpdate.dart';
import 'package:flutterapp/MessageUserId.dart';
import 'package:flutterapp/domains/messages/Message.dart';

import 'MessageVideoIdAndMessageBacklog.dart';

class MessageUtility {
  ReceivedMessage interpretMessage(String message) {
    SocketMessage socketMessage = new SocketMessage.fromMessage(message);

    debugPrint('received: ${socketMessage.buildString(0)}');

    Map<String, dynamic> messageContentMap = socketMessage.content.toMap();

    if (messageContentMap.containsKey('sid')) {
      return new SidMessage(messageContentMap);
    }

    switch (socketMessage.type) {
      case "userId":
        return new UserIdMessage(messageContentMap['value']);
      case "sendMessage":
        return new MessageSendMessage(messageContentMap['value']);
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