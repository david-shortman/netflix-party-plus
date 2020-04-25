class NPServerInfo {
  String _sessionId;
  String _serverId;
  int currentServerTime;

  bool isIncomplete() {
    return _sessionId == null || _serverId == null;
  }

  String getSessionId() {
    return _sessionId;
  }

  String getServerId() {
    return _serverId;
  }

  NPServerInfo({ String url }) {
    Uri uri = Uri.parse(url);
    _sessionId = uri.queryParameters['npSessionId'];
    _serverId = uri.queryParameters['npServerId'];
  }
}
