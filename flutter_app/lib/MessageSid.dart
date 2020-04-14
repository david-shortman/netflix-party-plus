import 'package:flutterapp/ReceivedMessage.dart';

class SidMessage extends ReceivedMessage {
  String sid;
  dynamic upgrades;
  int pingInterval;
  int pingTimeout;
  SidMessage(Map<String, dynamic> objectFromMessage) {
    sid = objectFromMessage['sid'] as String;
    upgrades = objectFromMessage['upgrades'];
    pingInterval = objectFromMessage['pingInterval'] as int;
    pingTimeout = objectFromMessage['pingTimeout'] as int;
  }
}