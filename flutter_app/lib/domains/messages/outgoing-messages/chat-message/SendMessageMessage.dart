import 'package:flutterapp/domains/messages/outgoing-messages/chat-message/SendMessageContent.dart';

import '../../Message.dart';

class SendMessageMessage extends SocketMessage {
  String type = 'sendMessage';

  SendMessageMessage(SendMessageContent content) {
    this.content = content;
  }
}