import 'package:dash_chat/dash_chat.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutterapp/domains/messages/outgoing-messages/join-session/UserSettings.dart';
import 'package:flutterapp/domains/messages/outgoing-messages/typing/TypingContent.dart';
import 'package:flutterapp/domains/messages/outgoing-messages/typing/TypingMessage.dart';
import 'package:flutterapp/domains/messenger/Messenger.dart';
import 'package:flutterapp/theming/UserColors.dart';

class ChatStream {
  static Widget getChatStream(
      {BuildContext context,
      List<ChatMessage> messages,
      Function(ChatMessage) onSend,
      UserSettings userSettings,
      ScrollController scrollController,
      Messenger messenger}) {
    String icon = userSettings.getIcon();
    return DashChat(
      messages: messages,
      onSend: (text) {
        onSend(text);
      },
      onTextChange: (text) {
        debugPrint('henlo $text');
        messenger.sendMessage(new TypingMessage(new TypingContent(true)));
        Future.delayed(new Duration(seconds: 3), () async {
          messenger.sendMessage(new TypingMessage(new TypingContent(false)));
        });
      },
      user: ChatUser(
          name: userSettings.getNickname(),
          uid: userSettings.getId(),
          avatar: icon,
          containerColor: UserColors.getColor(icon)),
      scrollController: scrollController,
      messageTextBuilder: (text) {
        return new Text(
          text,
          style: new TextStyle(color: Colors.white),
        );
      },
      showUserAvatar: true,
      scrollToBottom: false,
      messageTimeBuilder: (text) {
        return new Text(
          text,
          style: new TextStyle(color: Colors.white, fontSize: 10),
        );
      },
      sendButtonBuilder: (onPressed) {
        return new CupertinoButton(
            child: Icon(CupertinoIcons.up_arrow),
            color: Theme.of(context).primaryColor,
            padding: EdgeInsets.all(3),
            minSize: 30,
            borderRadius: BorderRadius.circular(500),
            onPressed: onPressed);
      },
      inputToolbarPadding: EdgeInsets.fromLTRB(0, 0, 10, 0),
      messageContainerDecoration: new BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(15)),
      inputContainerStyle: new BoxDecoration(
          color: Theme.of(context).dialogBackgroundColor,
          borderRadius: BorderRadius.circular(30)),
      avatarBuilder: (chatUser) {
        return new SvgPicture.asset('assets/avatars/${chatUser.avatar}',
            height: 35);
      },
    );
  }
}
