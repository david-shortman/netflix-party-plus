import 'ReceivedMessage.dart';

class ErrorMessage extends ReceivedMessage {
  String errorMessage;

  ErrorMessage(Map<String, dynamic> objectFromMessage) {
    errorMessage = objectFromMessage['errorMessage'] as String;
  }
}
