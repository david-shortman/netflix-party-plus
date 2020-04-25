import 'package:np_plus/domains/user/LocalUser.dart';
import 'package:np_plus/store/LocalUserStore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalUserService {
  LocalUserStore _localUserStore;

  LocalUserService(LocalUserStore localUserStore) {
    _localUserStore = localUserStore;
  }

  void initializeLocalUserFromSharedPreferences() {
    _onLocalUserUpdated();
  }

  Future<LocalUser> getLocalUser() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return LocalUser(
      username: await sharedPreferences.getString("username"),
      icon: await sharedPreferences.getString("userIcon"),
      id: await sharedPreferences.getString("userId"),
    );
  }

  void updateSavedLocalUser(LocalUser localUser) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setString("username", localUser.username);
    await sharedPreferences.setString("userIcon", localUser.icon);
    await sharedPreferences.setString("userId", localUser.id);
    _onLocalUserUpdated();
  }

  void updateProfile({String username, String icon}) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setString(
        "username", username ?? _localUserStore.localUser.username);
    await sharedPreferences.setString(
        "userIcon", icon ?? _localUserStore.localUser.icon);
    _onLocalUserUpdated();
  }

  void _onLocalUserUpdated() async {
    _localUserStore.updateLocalUser(await getLocalUser());
  }
}
