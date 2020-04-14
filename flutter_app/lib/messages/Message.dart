import 'dart:convert';

import 'package:flutterapp/messages/MessageContent.dart';

class SocketMessage {
  MessageContent content;
  String type = "unknown";

  String buildString(int sequenceNumber) {
    return '42$sequenceNumber[\"$type\",${json.encode(content.toMap())}]';
  }
}
