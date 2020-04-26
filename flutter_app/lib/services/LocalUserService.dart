import 'package:np_plus/domains/user/LocalUser.dart';
import 'package:np_plus/store/LocalUserStore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../vaults/DefaultsVault.dart';

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
    String username =
        await sharedPreferences.getString("username") ?? "Mobile User";
    return LocalUser(
      username: username != "" ? username : DefaultsVault.DEFAULT_AVATAR,
      icon: await sharedPreferences.getString("userIcon") ??
          DefaultsVault.DEFAULT_AVATAR,
      id: await sharedPreferences.getString("userId"),
    );
  }

  void updateUserId(String userId) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setString(
        "userId", userId ?? _localUserStore.localUser.id);
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
