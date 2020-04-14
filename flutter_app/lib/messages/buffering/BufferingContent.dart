import 'package:flutterapp/messages/MessageContent.dart';

class BufferingContent extends MessageContent {
  bool _isBuffering;

  BufferingContent(bool isBuffering) {
    this._isBuffering = isBuffering;
  }

  Map<String, dynamic> toMap() =>
      {
        'buffering': _isBuffering
      };
}
