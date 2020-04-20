import 'dart:convert';

import 'package:flutterapp/domains/messages/MessageArray.dart';
import 'package:flutterapp/domains/messages/outgoing-messages/dynamic/DynamicMessageContent.dart';
import 'package:flutterapp/domains/messages/outgoing-messages/dynamic/SingleValueDynamicMessageContent.dart';
import 'package:flutterapp/domains/messages/outgoing-messages/empty-message/EmptyMessage.dart';

import 'MessageContent.dart';
import 'SerializedMessageType.dart';

class SocketMessage {
  MessageContent content;
  String type = "unknown";

  SocketMessage();

  SocketMessage.fromString(String message) {
    int indexOfOpenBracket = message.indexOf('[');
    int indexOfOpenBrace = message.indexOf('{');

    SerializedMessageType serializedMessageType =
        _getSerializedMessageType(message);

    switch (serializedMessageType) {
      case SerializedMessageType.EMPTY:
        content = EmptyMessageContent();
        break;
      case SerializedMessageType.MAP:
        message = message.substring(indexOfOpenBrace);
        content = DynamicMessageContent(json.decode(message));
        break;
      case SerializedMessageType.ARRAY:
        message = message.substring(indexOfOpenBracket);
        MessageArray messageArray = MessageArray(message);

        int propertyBagListLength = messageArray.propertyBagList.length;
        if (propertyBagListLength == 1) {
          content =
              SingleValueDynamicMessageContent(messageArray.propertyBagList[0]);
        } else if (propertyBagListLength > 1) {
          type = messageArray.propertyBagList[0];
          if (!(content is Map)) {
            content = SingleValueDynamicMessageContent(
                messageArray.propertyBagList[1]);
          } else {
            content = DynamicMessageContent(messageArray.propertyBagList[1]);
          }
        } else {
          content = EmptyMessageContent();
        }
        break;
    }
  }

  SerializedMessageType _getSerializedMessageType(String message) {
    int indexOfOpenBracket = message.indexOf('[');
    int indexOfOpenBrace = message.indexOf('{');

    if (indexOfOpenBracket == -1 && indexOfOpenBrace == -1) {
      return SerializedMessageType.EMPTY;
    }
    if (indexOfOpenBrace != -1 && indexOfOpenBrace < indexOfOpenBracket) {
      return SerializedMessageType.MAP;
    }
    return SerializedMessageType.ARRAY;
  }

  String buildString(int sequenceNumber) {
    return '42$sequenceNumber[\"$type\",${json.encode(content.toMap())}]';
  }
}
