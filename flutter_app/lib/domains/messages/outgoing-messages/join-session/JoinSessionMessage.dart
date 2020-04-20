import 'package:flutterapp/domains/messages/outgoing-messages/join-session/JoinSessionContent.dart';

import '../../SocketMessage.dart';

class JoinSessionMessage extends SocketMessage {
  String type = 'joinSession';

  JoinSessionMessage(JoinSessionContent content) {
    super.content = content;
  }
}
