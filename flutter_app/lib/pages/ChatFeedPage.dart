import 'dart:async';

import 'package:dash_chat/dash_chat.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_interactive_keyboard/flutter_interactive_keyboard.dart';
import 'package:np_plus/GetItInstance.dart';
import 'package:np_plus/vaults/DefaultsVault.dart';
import 'package:np_plus/domains/messages/outgoing-messages/chat-message/SendMessageBody.dart';
import 'package:np_plus/domains/messages/outgoing-messages/chat-message/SendMessageContent.dart';
import 'package:np_plus/domains/messages/outgoing-messages/chat-message/SendMessageMessage.dart';
import 'package:np_plus/domains/messages/outgoing-messages/typing/TypingContent.dart';
import 'package:np_plus/domains/messages/outgoing-messages/typing/TypingMessage.dart';
import 'package:np_plus/services/SocketMessengerService.dart';
import 'package:np_plus/domains/user/LocalUser.dart';
import 'package:np_plus/store/LocalUserStore.dart';
import 'package:np_plus/store/PartySessionStore.dart';
import 'package:np_plus/store/ChatMessagesStore.dart';
import 'package:np_plus/store/PlaybackInfoStore.dart';
import 'package:np_plus/theming/AvatarColors.dart';
import 'package:np_plus/utilities/TimeUtility.dart';
import 'package:rxdart/rxdart.dart';

class ChatFeedPage extends StatefulWidget {
  ChatFeedPage({Key key}) : super(key: key);

  @override
  _ChatFeedPageState createState() => _ChatFeedPageState(key: key);
}

class _ChatFeedPageState extends State<ChatFeedPage> {
  final _messenger = getIt.get<SocketMessengerService>();

  final _partySessionStore = getIt.get<PartySessionStore>();
  final _playbackInfoStore = getIt.get<PlaybackInfoStore>();
  final _chatMessagesStore = getIt.get<ChatMessagesStore>();
  final _localUserStore = getIt.get<LocalUserStore>();

  StreamSubscription<List<ChatMessage>> _chatMessageListener;

  ScrollController _chatScrollController = ScrollController();

  final ServerTimeUtility _serverTimeUtility = ServerTimeUtility();

  final BehaviorSubject<bool> _showUserBubbleAsAvatar =
      BehaviorSubject.seeded(true);

  final GlobalKey _chatKey = GlobalKey<DashChatState>();

  int _lastMessagesCount = 0;

  _ChatFeedPageState({Key key});

  void _setupNewChatMessagesListener() {
    _chatMessageListener = _chatMessagesStore.stream$
        .debounceTime(Duration(milliseconds: 100))
        .listen(_onChatMessagesChanged);
  }

  void _onChatMessagesChanged(List<ChatMessage> chatMessages) {
    if (chatMessages.length > _lastMessagesCount) {
      if (_chatScrollController.hasClients) {
        _scrollToBottomOfChatStream();
      }
      HapticFeedback.mediumImpact();
    }
    _lastMessagesCount = chatMessages.length;
  }

  void _scrollToBottomOfChatStream() {
    _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.linear);
  }

  String _messageInputText = '';
  TextEditingController _messageInputTextEditingController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    if (_chatMessageListener == null) {
      _setupNewChatMessagesListener();
    }
    return StreamBuilder(
      stream: _chatMessagesStore.stream$.withLatestFrom(
          _localUserStore.stream$,
          (chatMessages, localUser) =>
              {'chatMessages': chatMessages, 'localUser': localUser}),
      builder: (context, streamSnapshot) {
        if (streamSnapshot.data == null) {
          return Container();
        }
        LocalUser localUser = streamSnapshot.data['localUser'];
        bool isDarkMode =
            MediaQuery.of(context).platformBrightness == Brightness.dark;
        return KeyboardManagerWidget(
          child: DashChat(
            key: _chatKey,
            shouldShowLoadEarlier: false,
            onLoadEarlier: () {},
            messages: streamSnapshot.data['chatMessages'],
            scrollController: _chatScrollController,
            scrollToBottom: false,
            user: ChatUser(
                name: localUser?.username,
                uid: localUser?.id,
                avatar: localUser?.icon ?? DefaultsVault.DEFAULT_AVATAR,
                containerColor: AvatarColors.getColor(localUser?.icon ?? '')),
            text: _messageInputText,
            inputDecoration: InputDecoration(
                isDense: true,
                hintStyle: TextStyle(color: Colors.grey[400]),
                hintText: "Send a message",
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.fromLTRB(4, 8, 4, 8)),
            textController: _messageInputTextEditingController,
            onTextChange: (newText) {
              _messenger.sendMessage(TypingMessage(TypingContent(true)));
              Future.delayed(Duration(milliseconds: 1500), () async {
                _messenger.sendMessage(TypingMessage(TypingContent(false)));
              });
              _setChatInputTextState(newText);
            },
            inputToolbarPadding: EdgeInsets.fromLTRB(2, 0, 3, 0),
            inputContainerStyle: BoxDecoration(
                border: Border.all(color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.grey[300] : Colors.grey[800]),
                color: Theme.of(context).dialogBackgroundColor,
                borderRadius: BorderRadius.circular(30)),
            sendButtonBuilder: (onPressed) {
              return CupertinoButton(
                  child: Icon(CupertinoIcons.up_arrow),
                  color: Theme.of(context).primaryColor,
                  padding: EdgeInsets.all(3),
                  minSize: 30,
                  borderRadius: BorderRadius.circular(500),
                  onPressed: onPressed);
            },
            onSend: (chatMessage) {
              HapticFeedback.lightImpact();
              _sendChatMessage(chatMessage);
            },
            showUserAvatar: true,
            avatarBuilder: (chatUser) => StreamBuilder(
              stream: _showUserBubbleAsAvatar.stream,
              builder: (context, showUserBubbleAsAvatarSnapshot) {
                if (showUserBubbleAsAvatarSnapshot.data == false) {
                  String firstTwoLettersOfUsername = chatUser.name != null &&
                      chatUser.name.isNotEmpty
                      ? '${chatUser.name[0].toUpperCase()}${chatUser.name.length > 1 ? '${chatUser.name[1]}' : ''}'
                      : '?';
                  return Container(
                    width: 35,
                    height: 35,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        firstTwoLettersOfUsername,
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                    decoration: BoxDecoration(
                        color: AvatarColors.getColor(chatUser.avatar),
                        shape: BoxShape.circle),
                  );
                }
                String avatar = chatUser?.avatar != ''
                    ? chatUser?.avatar ?? DefaultsVault.DEFAULT_AVATAR.toString()
                    : DefaultsVault.DEFAULT_AVATAR.toString();
                return SvgPicture.asset('assets/avatars/${avatar}', height: 35);
              },
            ),
            onLongPressAvatar: (user) {
              HapticFeedback.lightImpact();
              _showUserBubbleAsAvatar.add(!_showUserBubbleAsAvatar.value);
            },
            messageTextBuilder: (text, [chatMessage]) {
              return Text(
                text,
                style: TextStyle(color: Colors.white),
              );
            },
            messageTimeBuilder: (time, [chatMessage]) {
              return Text(
                time,
                style: TextStyle(color: Colors.white, fontSize: 10),
              );
            },
            messageContainerDecoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(15)),
          ),
        );
      },
    );
  }

  void _sendChatMessage(ChatMessage chatMessage) {
    _messenger.sendMessage(SendMessageMessage(SendMessageContent(
        SendMessageBody(
            chatMessage.text,
            false,
            _serverTimeUtility.getCurrentServerTimeAdjustedForCurrentTime(
                _partySessionStore.partySession.getServerTime(),
                _playbackInfoStore
                    .playbackInfo.serverTimeAtLastVideoStateUpdate),
            _localUserStore.localUser.id,
            _localUserStore.localUser.id,
            _localUserStore.localUser.icon,
            _localUserStore.localUser.username))));
  }

  void _setChatInputTextState(String text) {
    setState(() {
      _messageInputText = text;
    });
  }

  @override
  void dispose() {
    super.dispose();
    _chatMessageListener.cancel();
  }
}
