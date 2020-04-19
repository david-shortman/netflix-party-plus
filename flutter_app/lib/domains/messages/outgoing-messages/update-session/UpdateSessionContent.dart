import 'package:flutterapp/domains/messages/MessageContent.dart';

class UpdateSessionContent implements MessageContent {
  int _lastKnownTime;
  int _lastKnownTimeUpdatedAt;
  String _state;
  int _lastKnownTimeRemaining;
  String _lastKnownTimeRemainingText;
  int _videoDuration;
  bool _isBuffering;

  UpdateSessionContent(
      int lastKnownTime,
      int lastKnownTimeUpdatedAt,
      String state,
      int lastKnownTimeRemaining,
      String lastKnownTimeRemainingText,
      int videoDuration,
      bool isBuffering) {
    _lastKnownTime = lastKnownTime;
    _lastKnownTimeUpdatedAt = lastKnownTimeUpdatedAt;
    _state = state;
    _lastKnownTimeRemaining = lastKnownTimeRemaining;
    _lastKnownTimeRemainingText = lastKnownTimeRemainingText;
    _videoDuration = videoDuration;
    _isBuffering = isBuffering;
  }

  @override
  Map<String, dynamic> toMap() => {
        'lastKnownTime': _lastKnownTime,
        'lastKnownTimeUpdatedAt': _lastKnownTimeUpdatedAt,
        'state': _state,
        'lastKnownTimeRemaining': _lastKnownTimeRemaining,
        'lastKnownTimeRemainingText': _lastKnownTimeRemainingText,
        'videoDuration': _videoDuration,
        'bufferingState': _isBuffering
      };
}
