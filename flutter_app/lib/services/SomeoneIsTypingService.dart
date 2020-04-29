import 'package:dash_chat/dash_chat.dart';
import 'package:np_plus/store/ChatMessagesStore.dart';

class SomeoneIsTypingService {
  ChatMessagesStore _chatMessagesStore;

  SomeoneIsTypingService(ChatMessagesStore chatMessagesStore) {
    _chatMessagesStore = chatMessagesStore;
  }

  void setSomeoneTyping() {
    _chatMessagesStore.setIsSomeoneTyping(true);
  }

  void setNoOneTyping() {
    _chatMessagesStore.setIsSomeoneTyping(false);
  }
}
