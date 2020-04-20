import 'package:flutterapp/domains/messages/MessageContent.dart';

class SingleValueDynamicMessageContent implements MessageContent {
  dynamic _value;

  SingleValueDynamicMessageContent(dynamic value) {
    _value = value;
  }

  @override
  Map<String, dynamic> toMap() {
    return {'value': _value};
  }
}
