import '../../SocketMessage.dart';
import 'TypingContent.dart';

class TypingMessage extends SocketMessage {
  String type = 'typing';

  TypingMessage(TypingContent content) {
    super.content = content;
  }
}
