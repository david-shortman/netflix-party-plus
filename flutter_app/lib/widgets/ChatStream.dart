import 'package:dash_chat/dash_chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutterapp/domains/messages/outgoing-messages/join-session/UserSettings.dart';
import 'package:flutterapp/theming/UserColors.dart';

class ChatStream {
  static Widget getChatStream(
      {BuildContext context,
      List<ChatMessage> messages,
      Function(ChatMessage) onSend,
      UserSettings userSettings,
      ScrollController scrollController}) {
    String icon = userSettings.getIcon();
    return DashChat(
      messages: messages,
      onSend: onSend,
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
      messageTimeBuilder: (text) {
        return new Text(
          text,
          style: new TextStyle(color: Colors.white, fontSize: 10),
        );
      },
      messageContainerDecoration:
          new BoxDecoration(color: Theme.of(context).cardColor),
      inputContainerStyle:
          new BoxDecoration(color: Theme.of(context).dialogBackgroundColor),
      avatarBuilder: (chatUser) {
        return new SvgPicture.asset('assets/avatars/${chatUser.avatar}',
            height: 35);
      },
    );
  }
}
