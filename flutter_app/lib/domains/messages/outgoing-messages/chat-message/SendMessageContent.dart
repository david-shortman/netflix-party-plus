import 'package:flutterapp/domains/messages/MessageContent.dart';

import 'SendMessageBody.dart';

class SendMessageContent implements MessageContent {
  SendMessageBody _content;

  SendMessageContent(SendMessageBody content) {
    this._content = content;
  }

  @override
  Map<String, dynamic> toMap() => _content.toMap();
}
