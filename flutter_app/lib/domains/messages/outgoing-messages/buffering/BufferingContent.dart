import 'package:np_plus/domains/messages/MessageContent.dart';

class BufferingContent implements MessageContent {
  bool _isBuffering;

  BufferingContent(bool isBuffering) {
    this._isBuffering = isBuffering;
  }

  @override
  Map<String, dynamic> toMap() => {'buffering': _isBuffering};
}
