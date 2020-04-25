class NPServerInfo {
  String _sessionId;
  String _serverId;
  int _serverTime;
  int _serverTimeLastUpdatedTime;

  bool isIncomplete() {
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
    return _serverTime +
        DateTime.now().millisecondsSinceEpoch -
        _serverTimeLastUpdatedTime;
  }

  NPServerInfo();

  NPServerInfo.fromUrl({String url}) {
    Uri uri = Uri.parse(url);
    _sessionId = uri.queryParameters['npSessionId'];
    _serverId = uri.queryParameters['npServerId'];
  }

  NPServerInfo.fromNPServerInfo(NPServerInfo npServerInfo,
      {int newServerTime, int newServerTimeLastUpdatedTime}) {
    _serverId = npServerInfo.getServerId();
    _sessionId = npServerInfo.getSessionId();

    if (newServerTime >= 0) {
      _serverTime = newServerTime;
    } else {
      _serverTime = npServerInfo.getServerTime();
    }

    if (newServerTime >= 0) {
      _serverTimeLastUpdatedTime = newServerTimeLastUpdatedTime;
    } else {
      _serverTimeLastUpdatedTime = npServerInfo.getServerTimeLastUpdatedTime();
    }
  }
}
