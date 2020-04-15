import 'package:flutterapp/domains/messages/broadcastUserSettings/BroadcastUserSettingsContent.dart';

import '../Message.dart';

class BroadcastUserSettingsMessage extends SocketMessage {
  String type = 'broadcastUserSettings';

  BroadcastUserSettingsMessage(BroadCastUserSettingsContent content) {
    this.content = content;
  }
}