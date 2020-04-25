import 'package:dash_chat/dash_chat.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:np_plus/domains/messages/outgoing-messages/join-session/UserSettings.dart';
import 'package:np_plus/domains/messages/outgoing-messages/typing/TypingContent.dart';
import 'package:np_plus/domains/messages/outgoing-messages/typing/TypingMessage.dart';
import 'package:np_plus/domains/messenger/SocketMessenger.dart';
import 'package:np_plus/theming/AvatarColors.dart';

class ChatStream {
  static Widget getChatStream(
      {BuildContext context,
      Function setTextState,
      List<ChatMessage> messages,
      Function(ChatMessage) onSend,
      UserSettings userSettings,
      ScrollController scrollController,
      TextEditingController textEditingController,
      String text,
      SocketMessenger messenger}) {
    String icon = userSettings.getIcon();
    TextEditingController textEditingController = TextEditingController();
    return DashChat(
      messages: messages,
      onSend: onSend,
      text: text,
      textController: textEditingController,
      onTextChange: (newText) {
        messenger.sendMessage(TypingMessage(TypingContent(true)));
        Future.delayed(Duration(milliseconds: 1500), () async {
          messenger.sendMessage(TypingMessage(TypingContent(false)));
        });
        setTextState(newText);
      },
      user: ChatUser(
          name: userSettings.getNickname(),
          uid: userSettings.getId(),
          avatar: icon,
          containerColor: AvatarColors.getColor(icon)),
      scrollController: scrollController,
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
        return SvgPicture.asset('assets/avatars/${chatUser.avatar}',
            height: 35);
      },
    );
  }
}
