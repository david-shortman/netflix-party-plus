class PartySession {
  String _sessionId;
  String _serverId;
  int _serverTime;
  int _serverTimeLastUpdatedTime;
  bool _isSessionActive = false;

  bool isMetadataIncomplete() {
    return _sessionId == null || _serverId == null;
  }

  String getSessionId() {
    return _sessionId;
  }

  String getServerId() {
    return _serverId;
  }

  int getServerTime() {
    return _serverTime;
  }

  int getServerTimeLastUpdatedTime() {
    return _serverTimeLastUpdatedTime;
  }

  int getServerTimeAdjustedForTimeSinceLastServerTimeUpdate() {
    if (_serverTime == null) {
      _serverTime = 0;
    }
    if (_serverTimeLastUpdatedTime == null) {
      _serverTimeLastUpdatedTime = 0;
    }
    return _serverTime +
        DateTime.now().millisecondsSinceEpoch -
        _serverTimeLastUpdatedTime;
  }

  PartySession();

  PartySession.fromUrl({String url}) {
    Uri uri = Uri.parse(url);
    _sessionId = uri.queryParameters['npSessionId'];
    _serverId = uri.queryParameters['npServerId'];
  }

  PartySession.fromPartySessionAndSessionActive(
      PartySession partySession, bool isSessionActive) {
    _serverId = partySession.getServerId();
    _sessionId = partySession.getSessionId();
    _serverTime = partySession.getServerTime();
    _serverId = partySession.getServerId();
    _isSessionActive = isSessionActive;
  }

  PartySession.fromPartySession(PartySession partySession,
      {int newServerTime,
      int newServerTimeLastUpdatedTime,
      bool isSessionActive}) {
    _serverId = partySession.getServerId();
    _sessionId = partySession.getSessionId();

    if (newServerTime != 0) {
      _serverTime = newServerTime;
    } else {
      _serverTime = partySession.getServerTime();
    }

    if (newServerTime != 0) {
      _serverTimeLastUpdatedTime = newServerTimeLastUpdatedTime;
    } else {
      _serverTimeLastUpdatedTime = partySession.getServerTimeLastUpdatedTime();
    }

    if (isSessionActive != null) {
      _isSessionActive = isSessionActive;
    } else {
      _isSessionActive = partySession.isSessionActive();
    }
  }

  bool isSessionActive() {
    return _isSessionActive;
  }
}
