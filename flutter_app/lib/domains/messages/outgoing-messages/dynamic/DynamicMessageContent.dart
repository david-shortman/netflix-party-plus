import 'package:flutterapp/domains/messages/MessageContent.dart';

class DynamicMessageContent implements MessageContent {
  Map<String, dynamic> _content;

  DynamicMessageContent(dynamic content) {
    _content = content;
  }

  @override
  Map<String, dynamic> toMap() {
    return _content;
  }
}