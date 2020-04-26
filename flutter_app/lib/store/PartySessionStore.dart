import 'package:np_plus/domains/server/ServerInfo.dart';
import 'package:rxdart/rxdart.dart';

class PartySessionStore {
  BehaviorSubject<PartySession> _partySession =
      BehaviorSubject.seeded(PartySession());

  ValueStream<PartySession> get stream$ => _partySession.stream;
  PartySession get partySession => _partySession.value;

  void updateServerTime(int newServerTime) {
    _partySession.add(PartySession.fromPartySession(partySession,
        newServerTime: newServerTime,
        newServerTimeLastUpdatedTime: DateTime.now().millisecondsSinceEpoch));
  }

  void updatePartySession(PartySession partySession) {
    _partySession.add(partySession);
  }

  void setAsSessionInactive() {
    _partySession.add(PartySession.fromPartySession(partySession,
        newServerTime: 0,
        newServerTimeLastUpdatedTime: 0,
        isSessionActive: false));
  }

  void setAsSessionActive() {
    _partySession.add(
        PartySession.fromPartySession(partySession, isSessionActive: true));
  }

  bool isSessionActive() {
    return partySession.isSessionActive();
  }
}
