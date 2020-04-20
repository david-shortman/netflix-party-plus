import '../../SocketMessage.dart';
import 'BroadcastUserSettingsContent.dart';

class BroadcastUserSettingsMessage extends SocketMessage {
  String type = 'broadcastUserSettings';

  BroadcastUserSettingsMessage(BroadCastUserSettingsContent content) {
    this.content = content;
  }
}
