class PlaybackInfo {
  int serverTimeAtLastVideoStateUpdate = 0;
  int lastKnownMoviePosition = 0;
  bool isPlaying;

  PlaybackInfo(
      {this.serverTimeAtLastVideoStateUpdate,
      this.lastKnownMoviePosition,
      this.isPlaying});

  PlaybackInfo.fromPlaybackInfo(PlaybackInfo playbackInfo,
      {int newServerTimeAtLastUpdate,
      int newLastKnownMoviePosition,
      bool newIsPlaying}) {
    if (newServerTimeAtLastUpdate != null) {
      serverTimeAtLastVideoStateUpdate = newServerTimeAtLastUpdate;
    } else {
      serverTimeAtLastVideoStateUpdate = playbackInfo.serverTimeAtLastVideoStateUpdate;
    }
    if (newLastKnownMoviePosition != null) {
      lastKnownMoviePosition = newLastKnownMoviePosition;
    } else {
      lastKnownMoviePosition = playbackInfo.lastKnownMoviePosition;
    }
    if (newIsPlaying != null) {
      isPlaying = newIsPlaying;
    } else {
      isPlaying = playbackInfo.isPlaying;
    }
  }
}
