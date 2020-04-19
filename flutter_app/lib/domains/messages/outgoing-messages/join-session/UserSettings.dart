import 'package:flutterapp/domains/mappable/Mappable.dart';

class UserSettings implements Mappable {
  bool _recentlyUpdated;
  String _userIcon;
  String _userId;
  String _userNickname;

  UserSettings(bool recentlyUpdated,
      String userIcon,
      String userId,
      String userNickname) {
    _recentlyUpdated = recentlyUpdated;
    _userIcon = userIcon;
    _userId = userId;
    _userNickname = userNickname;
  }

  String getNickname() {
    return _userNickname;
  }

  String getIcon() {
    return _userIcon;
  }

  String getId() {
    return _userId;
  }

  @override
  Map<String, dynamic> toMap() =>
      {
        'recentlyUpdated': _recentlyUpdated,
        'userIcon': _userIcon,
        'userId': _userId,
        'userNickname': _userNickname
      };
}
