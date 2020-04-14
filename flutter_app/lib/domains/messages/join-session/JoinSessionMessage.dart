import 'package:flutterapp/domains/messages/join-session/JoinSessionContent.dart';

import '../Message.dart';

class JoinSessionMessage extends SocketMessage {
  String type = 'joinSession';

  JoinSessionMessage(JoinSessionContent content) {
    super.content = content;
  }
}