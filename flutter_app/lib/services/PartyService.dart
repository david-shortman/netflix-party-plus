import 'dart:async';

import 'package:dash_chat/dash_chat.dart';
import 'package:flutter/cupertino.dart';
import 'package:np_plus/domains/avatar/Avatar.dart';
import 'package:np_plus/domains/media-controls/VideoState.dart';
import 'package:np_plus/domains/messages/incoming-messages/ErrorMessage.dart';
import 'package:np_plus/domains/messages/incoming-messages/ReceivedMessage.dart';
import 'package:np_plus/domains/messages/incoming-messages/ReceivedMessageUtility.dart';
import 'package:np_plus/domains/messages/incoming-messages/SentMessageMessage.dart';
import 'package:np_plus/domains/messages/incoming-messages/ServerTimeMessage.dart';
import 'package:np_plus/domains/messages/incoming-messages/SetPresenceMessage.dart';
import 'package:np_plus/domains/messages/incoming-messages/SidMessage.dart';
import 'package:np_plus/domains/messages/incoming-messages/UpdateMessage.dart';
import 'package:np_plus/domains/messages/incoming-messages/UserIdMessage.dart';
import 'package:np_plus/domains/messages/incoming-messages/UserMessage.dart';
import 'package:np_plus/domains/messages/incoming-messages/VideoIdAndMessageCatchupMessage.dart';
import 'package:np_plus/domains/messages/outgoing-messages/buffering/BufferingContent.dart';
import 'package:np_plus/domains/messages/outgoing-messages/buffering/BufferingMessage.dart';
import 'package:np_plus/domains/messages/outgoing-messages/join-session/JoinSessionContent.dart';
import 'package:np_plus/domains/messages/outgoing-messages/join-session/JoinSessionMessage.dart';
import 'package:np_plus/domains/messages/outgoing-messages/join-session/UserSettings.dart';
import 'package:np_plus/domains/messages/outgoing-messages/server-time/GetServerTimeContent.dart';
import 'package:np_plus/domains/messages/outgoing-messages/server-time/GetServerTimeMessage.dart';
import 'package:np_plus/domains/messages/outgoing-messages/update-session/UpdateSessionContent.dart';
import 'package:np_plus/domains/messages/outgoing-messages/update-session/UpdateSessionMessage.dart';
import 'package:np_plus/domains/playback/PlaybackInfo.dart';
import 'package:np_plus/services/SocketMessengerService.dart';
import 'package:np_plus/domains/server/ServerInfo.dart';
import 'package:np_plus/domains/user/LocalUser.dart';
import 'package:np_plus/services/LocalUserService.dart';
import 'package:np_plus/services/SomeoneIsTypingService.dart';
import 'package:np_plus/services/ToastService.dart';
import 'package:np_plus/store/ChatMessagesStore.dart';
import 'package:np_plus/store/PartySessionStore.dart';
import 'package:np_plus/store/PlaybackInfoStore.dart';
import 'package:np_plus/theming/AvatarColors.dart';

class PartyService {
  SocketMessengerService _messengerService;
  ToastService _toastService;
  PlaybackInfoStore _playbackInfoStore;
  ChatMessagesStore _chatMessagesStore;
  PartySessionStore _partySessionStore;
  LocalUserService _localUserService;
  SomeoneIsTypingService _someoneIsTypingService;
  Timer _getServerTimeTimer;
  Timer _pingServerTimer;
  PartySession _lastPartySession;

  PartyService(
      SocketMessengerService socketMessenger,
      ToastService toastService,
      PlaybackInfoStore playbackInfoStore,
      LocalUserService localUserService,
      ChatMessagesStore chatMessagesStore,
      SomeoneIsTypingService someoneIsTypingService,
      PartySessionStore partySessionStore) {
    _messengerService = socketMessenger;
    _toastService = toastService;
    _playbackInfoStore = playbackInfoStore;
    _localUserService = localUserService;
    _chatMessagesStore = chatMessagesStore;
    _someoneIsTypingService = someoneIsTypingService;
    _partySessionStore = partySessionStore;
  }

  void rejoinLastParty() {
    _toastService.showToastMessage("Reconnecting...");
    joinParty(null);
  }

  void joinParty(PartySession partySession) {
    if (partySession == null) {
      partySession = _lastPartySession;
    }
    _messengerService.establishConnection(
        "wss://${partySession.getServerId()}.netflixparty.com/socket.io/?EIO=3&transport=websocket",
        _onReceivedStreamMessage,
        _onConnectionClosed,
        _onConnectionOpened);
    _lastPartySession = partySession;
  }

  void _onReceivedStreamMessage(streamMessage) {
    ReceivedMessage receivedMessage =
        ReceivedMessageUtility.fromString(streamMessage);
    if (receivedMessage is UserIdMessage) {
      _onUserIdMessageReceived(receivedMessage);
    } else if (receivedMessage is ServerTimeMessage) {
      _onServerTimeMessageReceived(receivedMessage);
    } else if (receivedMessage is SetPresenceMessage) {
      _onSetPresenceMessageReceived(receivedMessage);
    } else if (receivedMessage is UpdateMessage) {
      _onUpdateMessageReceived(receivedMessage);
    } else if (receivedMessage is SidMessage) {
      _onSidMessageReceived(receivedMessage);
    } else if (receivedMessage is SentMessageMessage) {
      _onSentMessageMessageReceived(receivedMessage);
    } else if (receivedMessage is VideoIdAndMessageCatchupMessage) {
      _onCatchupMessageReceived(receivedMessage);
    } else if (receivedMessage is ErrorMessage) {
      _onErrorMessageReceived(receivedMessage);
    }
  }

  void _onErrorMessageReceived(ErrorMessage errorMessage) {
    _toastService.showToastMessage(errorMessage.errorMessage);
  }

  void _onUserIdMessageReceived(UserIdMessage userIdMessage) async {
    await _localUserService.updateUserId(userIdMessage.userId);
    _sendGetServerTimeMessage();
  }

  void _onServerTimeMessageReceived(ServerTimeMessage serverTimeMessage) {
    if (!_partySessionStore.isSessionActive()) {
      _joinSession(_partySessionStore.partySession.getSessionId());
    }
    _partySessionStore.updateServerTime(serverTimeMessage.serverTime);
  }

  void _onSetPresenceMessageReceived(SetPresenceMessage setPresenceMessage) {
    setPresenceMessage.anyoneTyping
        ? _someoneIsTypingService.setSomeoneTyping()
        : _someoneIsTypingService.setNoOneTyping();
  }

  void _onSentMessageMessageReceived(SentMessageMessage sentMessageMessage) {
    _chatMessagesStore.pushNewChatMessages(List.from([
      ChatMessage(
          createdAt: DateTime.fromMillisecondsSinceEpoch(
              sentMessageMessage.userMessage.timestamp),
          text: sentMessageMessage.userMessage.body,
          user: _buildChatUser(sentMessageMessage.userMessage))
    ]));
  }

  void _onSidMessageReceived(SidMessage sidMessage) {
    if (_getServerTimeTimer != null) {
      _getServerTimeTimer.cancel();
      _getServerTimeTimer = null;
    }
    _getServerTimeTimer = Timer.periodic(
        Duration(milliseconds: 5000), (Timer t) => _sendGetServerTimeMessage());
    if (_pingServerTimer != null) {
      _pingServerTimer.cancel();
      _pingServerTimer = null;
    }
    _pingServerTimer = Timer.periodic(
        Duration(milliseconds: sidMessage.pingInterval),
        (Timer t) => _messengerService.sendRawMessage("2"));
  }

  void _onUpdateMessageReceived(UpdateMessage updateMessage) {
    _playbackInfoStore.updatePlaybackInfo(PlaybackInfo(
        serverTimeAtLastVideoStateUpdate: updateMessage.lastKnownTimeUpdatedAt,
        lastKnownMoviePosition: updateMessage.lastKnownTime,
        isPlaying: updateMessage.state == VideoState.PLAYING,
        videoDuration: updateMessage.videoDuration));
    _sendNotBufferingMessage();
  }

  void _onCatchupMessageReceived(
      VideoIdAndMessageCatchupMessage catchupMessage) {
    debugPrint('catchup ${catchupMessage.lastKnownTime} ${catchupMessage.lastKnownTimeRemaining}');
    _playbackInfoStore.updatePlaybackInfo(PlaybackInfo(
        serverTimeAtLastVideoStateUpdate: catchupMessage.lastKnownTimeUpdatedAt,
        lastKnownMoviePosition: catchupMessage.lastKnownTime,
        isPlaying: catchupMessage.state == VideoState.PLAYING,
        videoDuration: catchupMessage.lastKnownTime +
            catchupMessage.lastKnownTimeRemaining));
    _addChatMessages(catchupMessage.userMessages);
    _sendNotBufferingMessage();
  }

  void _onConnectionOpened() {
    // TODO: does this matter?
  }

  void _onConnectionClosed() {
    _partySessionStore.setAsSessionInactive();
    if (_pingServerTimer.isActive) {
      _pingServerTimer.cancel();
    }
    if (_getServerTimeTimer.isActive) {
      _getServerTimeTimer.cancel();
    }
  }

  void _sendGetServerTimeMessage() {
    GetServerTimeContent getServerTimeContent = GetServerTimeContent("1.7.8");
    _messengerService.sendMessage(GetServerTimeMessage(getServerTimeContent));
  }

  void _joinSession(String sessionIdForJoin) async {
    LocalUser localUser = await _localUserService.getLocalUser();
    UserSettings userSettings =
        UserSettings(true, localUser.icon, localUser.id, localUser.username);
    JoinSessionContent joinSessionContent =
        JoinSessionContent(sessionIdForJoin, localUser.id, userSettings);
    _messengerService.sendMessage(JoinSessionMessage(joinSessionContent));
    _partySessionStore.setAsSessionActive();
  }

  void _addChatMessages(List<UserMessage> userMessages) {
    _chatMessagesStore.pushNewChatMessages(userMessages.map((userMessage) {
      return ChatMessage(
          text: userMessage.body, user: _buildChatUser(userMessage));
    }).toList());
  }

  ChatUser _buildChatUser(UserMessage userMessage) {
    return ChatUser.fromJson({
      'uid': userMessage.userId,
      'name': userMessage.userNickname,
      'avatar': UserAvatar.formatIconName(userMessage.userIcon),
      'containerColor': AvatarColors.getColor(userMessage.userIcon).value
    });
  }

  void _sendNotBufferingMessage() {
    BufferingContent bufferingContent = BufferingContent(false);
    _messengerService.sendMessage(BufferingMessage(bufferingContent));
  }

  void updateVideoState(String videoState, {int diff = 0, double percentage}) {
    if (percentage != null) {
      int newVideoPosition =
          (percentage * (_playbackInfoStore.playbackInfo.videoDuration ?? 0.0))
              .floor();
      _playbackInfoStore.updateLastKnownMoviePosition(newVideoPosition);
    } else {
      if (_playbackInfoStore.isPlaying()) {
        _playbackInfoStore.updateLastKnownMoviePosition(
            _getVideoPositionAdjustedForTimeSinceLastVideoStateUpdate() + diff);
      } else {
        _playbackInfoStore.updateLastKnownMoviePosition(
            _playbackInfoStore.playbackInfo.lastKnownMoviePosition + diff);
      }
    }
    _playbackInfoStore.updateVideoState(videoState);
    int estimatedServerTime = _partySessionStore.partySession
        .getServerTimeAdjustedForTimeSinceLastServerTimeUpdate();
    _updateSessionContent(
        videoState,
        _playbackInfoStore.playbackInfo.lastKnownMoviePosition,
        estimatedServerTime);
    _playbackInfoStore.updateServerTimeAtLastUpdate(estimatedServerTime);
  }

  void _updateSessionContent(
      String mediaState, int videoPosition, int lastKnownTimeUpdatedAt) {
    _messengerService.sendMessage(UpdateSessionMessage(UpdateSessionContent(
        videoPosition,
        lastKnownTimeUpdatedAt,
        mediaState,
        null,
        null,
        _playbackInfoStore.playbackInfo.videoDuration,
        false)));
  }

  int _getMillisecondsPassedSinceLastVideoStateUpdate() {
    return _getCurrentTimeMillisecondsSinceEpoch() -
        _playbackInfoStore.playbackInfo.serverTimeAtLastVideoStateUpdate;
  }

  int _getCurrentTimeMillisecondsSinceEpoch() {
    return DateTime.now().millisecondsSinceEpoch;
  }

  int _getVideoPositionAdjustedForTimeSinceLastVideoStateUpdate() {
    return _playbackInfoStore.playbackInfo.lastKnownMoviePosition +
        _getMillisecondsPassedSinceLastVideoStateUpdate();
  }
}
