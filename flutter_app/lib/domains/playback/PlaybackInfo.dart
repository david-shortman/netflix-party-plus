class PlaybackInfo {
  int serverTimeAtLastVideoStateUpdate = 0;
  int lastKnownMoviePosition = 0;
  bool isPlaying;
  int videoDuration = 0;

  PlaybackInfo(
      {this.serverTimeAtLastVideoStateUpdate,
      this.lastKnownMoviePosition,
      this.isPlaying,
      this.videoDuration});

  PlaybackInfo.fromPlaybackInfo(PlaybackInfo playbackInfo,
      {int newServerTimeAtLastUpdate,
      int newLastKnownMoviePosition,
      bool newIsPlaying,
      int newVideoDuration,
      int newProgressGuesstimate}) {
    if (newServerTimeAtLastUpdate != null) {
      serverTimeAtLastVideoStateUpdate = newServerTimeAtLastUpdate;
    } else {
      serverTimeAtLastVideoStateUpdate =
          playbackInfo.serverTimeAtLastVideoStateUpdate;
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
    if (newVideoDuration != null) {
      videoDuration = newVideoDuration;
    } else {
      videoDuration = playbackInfo.videoDuration;
    }
  }
}
