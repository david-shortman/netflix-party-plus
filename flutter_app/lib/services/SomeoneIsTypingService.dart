import 'package:dash_chat/dash_chat.dart';
import 'package:np_plus/store/ChatMessagesStore.dart';

class SomeoneIsTypingService {
  ChatMessagesStore _chatMessagesStore;

  SomeoneIsTypingService(ChatMessagesStore chatMessagesStore) {
    _chatMessagesStore = chatMessagesStore;
  }

  final ChatMessage _someoneIsTypingMessage = ChatMessage(
      text: "Someone is typing...",
      user: ChatUser(uid: "SOMEONE_IS_TYPING", avatar: ""));

  void setSomeoneTyping() {
    if (!_chatMessagesStore.chatMessages.contains(_someoneIsTypingMessage)) {
      _chatMessagesStore.pushNewChatMessages([_someoneIsTypingMessage]);
    }
  }

  void setNoOneTyping() {
    _chatMessagesStore.removeChatMessage(_someoneIsTypingMessage);
  }
}
