import 'package:flutterapp/domains/messages/outgoing-messages/join-session/UserSettings.dart';

import '../../MessageContent.dart';

class BroadCastUserSettingsContent extends MessageContent {
  UserSettings _content;

  BroadCastUserSettingsContent(UserSettings content) {
    this._content = content;
  }

  Map<String, dynamic> toMap() =>
      {
        'userSettings': _content.toMap()
      };
}