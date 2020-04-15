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

  @override
  Map<String, dynamic> toMap() =>
      {
        'recentlyUpdated': _recentlyUpdated,
        'userIcon': _userIcon,
        'userId': _userId,
        'userNickname': _userNickname
      };
}
