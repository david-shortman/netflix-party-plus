import 'package:flutterapp/domains/messages/outgoing-messages/server-time/GetServerTimeContent.dart';

import '../../Message.dart';

class GetServerTimeMessage extends SocketMessage {
  String type = 'getServerTime';

  GetServerTimeMessage(GetServerTimeContent content) {
    super.content = content;
  }
}