import 'package:flutterapp/domains/messages/incoming-messages/ReceivedMessage.dart';

class SetPresenceMessage extends ReceivedMessage {
  String type = 'setPresence';
  bool anyoneTyping;

  SetPresenceMessage(Map<String, dynamic> objectFromMessage) {
    anyoneTyping = objectFromMessage['anyoneTyping'] as bool;
  }
}
