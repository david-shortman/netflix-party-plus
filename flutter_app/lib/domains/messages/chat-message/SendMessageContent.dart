import 'package:flutterapp/domains/messages/MessageContent.dart';

import 'SendMessageBody.dart';

class SendMessageContent extends MessageContent {
  SendMessageBody _content;

  SendMessageContent(SendMessageBody content) {
    this._content = content;
  }

  Map<String, dynamic> toMap() => _content.toMap();
}
