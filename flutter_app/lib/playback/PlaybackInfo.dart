class PlaybackInfo {
  int localTimeAtLastUpdate;
  int lastKnownMoviePosition;
  bool isPlaying;

  PlaybackInfo(
      {this.localTimeAtLastUpdate,
      this.lastKnownMoviePosition,
      this.isPlaying});
}
