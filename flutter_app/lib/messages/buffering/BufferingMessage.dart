import 'package:flutterapp/messages/buffering/BufferingContent.dart';

import '../Message.dart';

class BufferingMessage extends SocketMessage {
  String type = 'buffering';

  BufferingMessage(BufferingContent content) {
    super.content = content;
  }
}