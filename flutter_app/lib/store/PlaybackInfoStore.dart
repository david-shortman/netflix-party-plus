import 'package:np_plus/playback/PlaybackInfo.dart';
import 'package:rxdart/rxdart.dart';

class PlaybackInfoStore {
  BehaviorSubject<PlaybackInfo> _playbackInfo =
      BehaviorSubject.seeded(PlaybackInfo(isPlaying: false));

  ValueStream<PlaybackInfo> get stream$ => _playbackInfo.stream;
  PlaybackInfo get playbackInfo => _playbackInfo.value;

  void updateAsPaused() {
    _playbackInfo
        .add(PlaybackInfo.fromPlaybackInfo(playbackInfo, newIsPlaying: false));
  }

  void updateAsPlaying() {
    _playbackInfo
        .add(PlaybackInfo.fromPlaybackInfo(playbackInfo, newIsPlaying: true));
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
