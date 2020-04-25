class ServerTimeUtility {
  ServerTimeUtility();

  int getMillisecondsSinceLastUpdate(int timeAtLastUpdate) {
    return this.getCurrentTimeMillisecondsSinceEpoch() - timeAtLastUpdate;
  }

  int getCurrentTimeMillisecondsSinceEpoch() {
    return DateTime.now().millisecondsSinceEpoch;
  }

  int getCurrentServerTimeAdjustedForCurrentTime(
      int currentServerTime, int timeAtLastUpdate) {
    return currentServerTime + getMillisecondsSinceLastUpdate(timeAtLastUpdate);
  }
}
