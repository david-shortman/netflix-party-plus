import 'package:flutterapp/domains/messages/MessageContent.dart';

class SendMessageBody implements MessageContent {
  String _text;
  bool _isSystemMessage;
  int _timestamp;
  String _userId;
  String _permId;
  String _userIcon;
  String _userNickname;

  SendMessageBody(String text, bool isSystemMessage, int timestamp,
      String userId, String permId, String userIcon, String userNickname) {
    _text = text;
    _isSystemMessage = isSystemMessage;
    _timestamp = timestamp;
    _userId = userId;
    _permId = permId;
    _userIcon = userIcon;
    _userNickname = userNickname;
  }

  @override
  Map<String, dynamic> toMap() => {
        'body': _text,
        'isSystemMessage': _isSystemMessage,
        'timestamp': _timestamp,
        'userId': _userId,
        'permId': _permId,
        'userIcon': _userIcon,
        'userNickname': _userNickname
      };
}
