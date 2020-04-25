import 'package:dash_chat/dash_chat.dart';
import 'package:rxdart/rxdart.dart';

class ChatMessagesStore {
  BehaviorSubject<List<ChatMessage>> _chatMessages =
      BehaviorSubject.seeded(List());

  ValueStream<List<ChatMessage>> get stream$ =>
      _chatMessages.stream;
  List<ChatMessage> get chatMessages =>
      _chatMessages.value;

  void pushNewChatMessages(List<ChatMessage> newChatMessages) {
    List<ChatMessage> combinedChatMessages = List();
    combinedChatMessages.addAll(_chatMessages.value);
    combinedChatMessages.addAll(newChatMessages);
    _chatMessages.add(combinedChatMessages);
  }

  void removeChatMessage(ChatMessage chatMessage) {
    _chatMessages.add(_chatMessages.value.where((message) => message != chatMessage).toList());
  }
}
