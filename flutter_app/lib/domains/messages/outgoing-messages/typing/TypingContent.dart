import 'package:np_plus/domains/messages/MessageContent.dart';

class TypingContent implements MessageContent {
  bool _typing = false;

  TypingContent(bool typing) {
    _typing = typing;
  }

  @override
  Map<String, dynamic> toMap() => {'typing': _typing};
}
