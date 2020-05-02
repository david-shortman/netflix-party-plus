import 'package:dash_chat/dash_chat.dart';
import 'package:rxdart/rxdart.dart';

class ChatMessagesStore {
  BehaviorSubject<List<ChatMessage>> _chatMessages =
      BehaviorSubject.seeded(List());

  ValueStream<List<ChatMessage>> get stream$ => _chatMessages.stream;
  List<ChatMessage> get chatMessages => _chatMessages.value;

  BehaviorSubject<List<ChatUser>> _chatUsers = BehaviorSubject.seeded(List());

  ValueStream<List<ChatUser>> get chatUserStream$ => _chatUsers.stream;
  List<ChatUser> get chatUsers => _chatUsers.value;

  BehaviorSubject<bool> _isSomeoneTyping = BehaviorSubject.seeded(false);

  ValueStream<bool> get isSomeoneTypingStream$ => _isSomeoneTyping.stream;
  bool get isSomeoneTyping => _isSomeoneTyping.value;

  void setIsSomeoneTyping(bool isSomeoneTyping) {
    _isSomeoneTyping.add(isSomeoneTyping);
  }

  void pushNewChatMessages(List<ChatMessage> newChatMessages) {
    List<ChatMessage> combinedChatMessages = List();
    combinedChatMessages.addAll(_chatMessages.value);
    combinedChatMessages.addAll(newChatMessages);
    _chatMessages.add(combinedChatMessages);

    List<ChatUser> combinedChatUsers = List();
    combinedChatUsers.addAll(_chatUsers.value);
    Set<String> uniqueUserUids = Set<String>();
    uniqueUserUids.addAll(combinedChatUsers.map((user) => user.uid));
    combinedChatUsers.addAll(newChatMessages
        .where((message) => uniqueUserUids.add(message.user.uid))
        .map((message) => message.user));
    Set<String> userUidsWhoLeftInMessages = newChatMessages
        .where((message) => message.text == "left")
        .map((message) => message.user.uid)
        .toSet();
    combinedChatUsers
        .removeWhere((user) => userUidsWhoLeftInMessages.contains(user.uid));
    _chatUsers.add(combinedChatUsers);
  }

  void clearMessages() {
    _chatMessages.add([]);
    _chatUsers.add([]);
  }

  void removeChatMessage(ChatMessage chatMessage) {
    _chatMessages.add(_chatMessages.value
        .where((message) => message != chatMessage)
        .toList());
  }
}
