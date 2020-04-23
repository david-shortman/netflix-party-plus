import 'package:np_plus/domains/messages/MessageContent.dart';

class EmptyMessageContent implements MessageContent {
  @override
  Map<String, dynamic> toMap() {
    return {};
  }
}
