import 'package:np_plus/domains/user/LocalUser.dart';
import 'package:rxdart/rxdart.dart';

class LocalUserStore {
  BehaviorSubject<LocalUser> _localUser = BehaviorSubject.seeded(LocalUser());

  ValueStream<LocalUser> get stream$ => _localUser.stream;
  LocalUser get localUser => _localUser.value;

  void updateLocalUser(LocalUser newLocalUser) {
    _localUser.add(newLocalUser);
  }
}
