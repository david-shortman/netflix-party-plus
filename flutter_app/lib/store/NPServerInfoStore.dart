import 'package:np_plus/domains/server/ServerInfo.dart';
import 'package:rxdart/rxdart.dart';

class NPServerInfoStore {
  BehaviorSubject<NPServerInfo> _npServerInfo =
      BehaviorSubject.seeded(NPServerInfo());

  ValueStream<NPServerInfo> get stream$ => _npServerInfo.stream;
  NPServerInfo get npServerInfo => _npServerInfo.value;

  void updateServerTime(int newServerTime) {
    _npServerInfo.add(NPServerInfo.fromNPServerInfo(npServerInfo,
        newServerTime: newServerTime,
        newServerTimeLastUpdatedTime: DateTime.now().millisecondsSinceEpoch));
  }

  void updateNPServerInfo(NPServerInfo npServerInfo) {
    _npServerInfo.add(npServerInfo);
  }
}
