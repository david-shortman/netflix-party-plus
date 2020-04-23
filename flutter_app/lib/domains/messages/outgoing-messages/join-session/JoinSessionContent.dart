import 'package:np_plus/domains/messages/MessageContent.dart';

import 'UserSettings.dart';

class JoinSessionContent implements MessageContent {
  String _sessionId;
  String _permId;
  UserSettings _userSettings;

  JoinSessionContent(
      String sessionId, String permId, UserSettings userSettings) {
    _sessionId = sessionId;
    _permId = permId;
    _userSettings = userSettings;
  }

  @override
  Map<String, dynamic> toMap() => {
        'sessionId': _sessionId,
        'permId': _permId,
        'userSettings': _userSettings.toMap()
      };
}
