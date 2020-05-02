import 'package:np_plus/domains/server/ServerInfo.dart';
import 'package:rxdart/rxdart.dart';

class PartySessionStore {
  BehaviorSubject<PartySession> _partySession =
      BehaviorSubject.seeded(PartySession());
  ValueStream<PartySession> get stream$ => _partySession.stream;
  PartySession get partySession => _partySession.value;

  BehaviorSubject<bool> _isSessionActive = BehaviorSubject.seeded(false);
  ValueStream<bool> get isSessionActive$ => _isSessionActive.stream;
  bool get isSessionActive => _isSessionActive.value;

  BehaviorSubject<bool> _wasLastDisconnectPerformedByUser =
      BehaviorSubject.seeded(true);
  ValueStream<bool> get wasLastDisconnectPerformedByUser$ =>
      _wasLastDisconnectPerformedByUser.stream;
  bool get wasLastDisconnectPerformedByUser =>
      _wasLastDisconnectPerformedByUser.value;

  void setWasLastDisconnectPerformedByUser(
      bool newWasLastDisconnectPerformedByUser) {
    _wasLastDisconnectPerformedByUser.add(newWasLastDisconnectPerformedByUser);
  }

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
        newServerTime: 0, newServerTimeLastUpdatedTime: 0));
    _isSessionActive.add(false);
  }

  void setAsSessionActive() {
    _partySession.add(PartySession.fromPartySession(partySession));
    _isSessionActive.add(true);
  }
}
