import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutterapp/domains/messages/MessageArray.dart';
import 'package:flutterapp/domains/messages/MessageContent.dart';
import 'package:flutterapp/domains/messages/dynamic/DynamicMessageContent.dart';
import 'package:flutterapp/domains/messages/dynamic/SingleValueDynamicMessageContent.dart';
import 'package:flutterapp/domains/messages/empty-message/EmptyMessage.dart';

class SocketMessage {
  MessageContent content;
  String type = "unknown";

  SocketMessage();

  SocketMessage.fromMessage(String message) {
    int indexOfOpenBracket = message.indexOf('[');

    if (indexOfOpenBracket == -1) {
      content = new EmptyMessageContent();
    }
    else {
      message = message.substring(indexOfOpenBracket);
      MessageArray messageArray = new MessageArray(message);

      int propertyBagListLength = messageArray.propertyBagList.length;
      if (propertyBagListLength == 1) {
        content = new SingleValueDynamicMessageContent(messageArray.propertyBagList[0]);
      }
      else if (propertyBagListLength > 1) {
        type = messageArray.propertyBagList[0];
        content = new DynamicMessageContent(messageArray.propertyBagList[1]);
      }
      else {
        content = new EmptyMessageContent();
      }

      debugPrint('set message as: type > $type | content > ${json.encode(content.toMap())}');
    }
  }

  String buildString(int sequenceNumber) {
    return '42$sequenceNumber[\"$type\",${json.encode(content.toMap())}]';
  }
}
