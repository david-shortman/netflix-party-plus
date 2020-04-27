import 'package:np_plus/domains/media-controls/VideoState.dart';
import 'package:np_plus/domains/playback/PlaybackInfo.dart';
import 'package:rxdart/rxdart.dart';

class PlaybackInfoStore {
  BehaviorSubject<PlaybackInfo> _playbackInfo =
      BehaviorSubject.seeded(PlaybackInfo(isPlaying: false));

  ValueStream<PlaybackInfo> get stream$ => _playbackInfo.stream;
  PlaybackInfo get playbackInfo => _playbackInfo.value;

  bool isPlaying() {
    return playbackInfo.isPlaying;
  }

  String getVideoState() {
    return playbackInfo.isPlaying ? VideoState.PLAYING : VideoState.PAUSED;
  }

  void updateVideoState(String videoState) {
    _playbackInfo.add(PlaybackInfo.fromPlaybackInfo(playbackInfo,
        newIsPlaying: videoState == VideoState.PLAYING));
  }

  void updateLastKnownMoviePosition(int newLastKnownMoviePosition) {
    _playbackInfo.add(PlaybackInfo.fromPlaybackInfo(playbackInfo,
        newLastKnownMoviePosition: newLastKnownMoviePosition));
  }

  void updateServerTimeAtLastUpdate(int newLocalTimeAtLastUpdate) {
    _playbackInfo.add(PlaybackInfo.fromPlaybackInfo(playbackInfo,
        newServerTimeAtLastUpdate: newLocalTimeAtLastUpdate));
  }

  void updatePlaybackInfo(PlaybackInfo newPlaybackInfo) {
    _playbackInfo.add(newPlaybackInfo);
  }
}
