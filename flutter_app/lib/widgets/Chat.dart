import 'package:dash_chat/dash_chat.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:np_plus/domains/messages/outgoing-messages/chat-message/SendMessageBody.dart';
import 'package:np_plus/domains/messages/outgoing-messages/chat-message/SendMessageContent.dart';
import 'package:np_plus/domains/messages/outgoing-messages/chat-message/SendMessageMessage.dart';
import 'package:np_plus/domains/messages/outgoing-messages/typing/TypingContent.dart';
import 'package:np_plus/domains/messages/outgoing-messages/typing/TypingMessage.dart';
import 'package:np_plus/domains/messenger/SocketMessenger.dart';
import 'package:np_plus/domains/user/LocalUser.dart';
import 'package:np_plus/main.dart';
import 'package:np_plus/store/NPServerInfoStore.dart';
import 'package:np_plus/store/PlaybackInfoStore.dart';
import 'package:np_plus/theming/AvatarColors.dart';
import 'package:np_plus/utilities/TimeUtility.dart';

class Chat extends StatefulWidget {
  final SocketMessenger messenger;
  final LocalUser user;
  final List<ChatMessage> chatMessages;
  final ScrollController chatStreamScrollController;

  Chat(
      {Key key,
      this.messenger,
      this.user,
      this.chatMessages,
      this.chatStreamScrollController})
      : super(key: key);

  @override
  _ChatState createState() => _ChatState(
      key: key,
      chatMessages: chatMessages,
      messenger: messenger,
      user: user,
      chatStreamScrollController: chatStreamScrollController);
}

class _ChatState extends State<Chat> {
  List<ChatMessage> chatMessages;
  SocketMessenger messenger;
  LocalUser user;

  final npServerInfoStore = getIt.get<NPServerInfoStore>();
  final _playbackInfoStore = getIt.get<PlaybackInfoStore>();

  Function(String) onSendMessagePressed;
  ScrollController chatStreamScrollController;

  ServerTimeUtility _serverTimeUtility = ServerTimeUtility();

  _ChatState(
      {Key key,
      this.chatMessages,
      this.messenger,
      this.user,
      this.onSendMessagePressed,
      this.chatStreamScrollController});

  String _messageInputText = '';
  TextEditingController _messageInputTextEditingController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return DashChat(
      messages: chatMessages,
      onSend: _sendChatMessage,
      text: _messageInputText,
      textController: _messageInputTextEditingController,
      onTextChange: (newText) {
        messenger.sendMessage(TypingMessage(TypingContent(true)));
        Future.delayed(Duration(milliseconds: 1500), () async {
          messenger.sendMessage(TypingMessage(TypingContent(false)));
        });
        _setChatInputTextState(newText);
      },
      user: ChatUser(
          name: user?.username,
          uid: user?.id,
          avatar: user?.icon ?? 'Batman.svg',
          containerColor: AvatarColors.getColor(user?.icon ?? '')),
      scrollController: chatStreamScrollController,
      messageTextBuilder: (text) {
        return Text(
          text,
          style: TextStyle(color: Colors.white),
        );
      },
      showUserAvatar: true,
      scrollToBottom: false,
      messageTimeBuilder: (text) {
        return Text(
          text,
          style: TextStyle(color: Colors.white, fontSize: 10),
        );
      },
      sendButtonBuilder: (onPressed) {
        return CupertinoButton(
            child: Icon(CupertinoIcons.up_arrow),
            color: Theme.of(context).primaryColor,
            padding: EdgeInsets.all(3),
            minSize: 30,
            borderRadius: BorderRadius.circular(500),
            onPressed: onPressed);
      },
      inputToolbarPadding: EdgeInsets.fromLTRB(0, 0, 10, 0),
      messageContainerDecoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(15)),
      inputContainerStyle: BoxDecoration(
          color: Theme.of(context).dialogBackgroundColor,
          borderRadius: BorderRadius.circular(30)),
      avatarBuilder: (chatUser) {
        return SvgPicture.asset('assets/avatars/${user?.icon}', height: 35);
      },
    );
  }

  void _sendChatMessage(ChatMessage chatMessage) {
    debugPrint("send message ${chatMessage.text}");
    messenger.sendMessage(SendMessageMessage(SendMessageContent(SendMessageBody(
        chatMessage.text,
        false,
        _serverTimeUtility.getCurrentServerTimeAdjustedForCurrentTime(
            npServerInfoStore.npServerInfo.getServerTime(), _playbackInfoStore.playbackInfo.serverTimeAtLastVideoStateUpdate),
        user.id,
        user.id,
        user.icon,
        user.username))));
  }

  void _setChatInputTextState(String text) {
    setState(() {
      _messageInputText = text;
    });
  }
}
