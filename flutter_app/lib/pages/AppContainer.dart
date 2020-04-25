import 'dart:async';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:dash_chat/dash_chat.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:np_plus/changelog/ChangelogService.dart';
import 'package:np_plus/domains/media-controls/VideoState.dart';
import 'package:np_plus/domains/messages/incoming-messages/ErrorMessage.dart';
import 'package:np_plus/domains/messages/incoming-messages/SetPresenceMessage.dart';
import 'package:np_plus/domains/server/ServerInfo.dart';
import 'package:np_plus/domains/user/LocalUser.dart';
import 'package:np_plus/main.dart';
import 'package:np_plus/playback/PlaybackInfo.dart';
import 'package:np_plus/services/LocalUserService.dart';
import 'package:np_plus/store/LocalUserStore.dart';
import 'package:np_plus/store/NPServerInfoStore.dart';
import 'package:np_plus/store/ChatMessagesStore.dart';
import 'package:np_plus/store/PlaybackInfoStore.dart';
import 'package:np_plus/services/SomeoneIsTypingService.dart';
import 'package:np_plus/theming/AppTheme.dart';
import 'package:np_plus/theming/AvatarColors.dart';
import 'package:np_plus/widgets/ChangelogDialogFactory.dart';
import 'package:np_plus/widgets/Chat.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:keyboard_visibility/keyboard_visibility.dart';
import 'package:progress_button/progress_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../domains/avatar/Avatar.dart';
import 'UserSettingsPage.dart';
import '../domains/messages/incoming-messages/ReceivedMessage.dart';
import '../domains/messages/incoming-messages/ReceivedMessageUtility.dart';
import '../domains/messages/incoming-messages/SentMessageMessage.dart';
import '../domains/messages/incoming-messages/ServerTimeMessage.dart';
import '../domains/messages/incoming-messages/SidMessage.dart';
import '../domains/messages/incoming-messages/UpdateMessage.dart';
import '../domains/messages/incoming-messages/UserIdMessage.dart';
import '../domains/messages/incoming-messages/UserMessage.dart';
import '../domains/messages/incoming-messages/VideoIdAndMessageCatchupMessage.dart';
import '../domains/messages/outgoing-messages/broadcast-user-settings/BroadCastUserSettingsMessage.dart';
import '../domains/messages/outgoing-messages/broadcast-user-settings/BroadcastUserSettingsContent.dart';
import '../domains/messages/outgoing-messages/buffering/BufferingContent.dart';
import '../domains/messages/outgoing-messages/buffering/BufferingMessage.dart';
import '../domains/messages/outgoing-messages/join-session/JoinSessionContent.dart';
import '../domains/messages/outgoing-messages/join-session/JoinSessionMessage.dart';
import '../domains/messages/outgoing-messages/join-session/UserSettings.dart';
import '../domains/messages/outgoing-messages/server-time/GetServerTimeContent.dart';
import '../domains/messages/outgoing-messages/server-time/GetServerTimeMessage.dart';
import '../domains/messages/outgoing-messages/update-session/UpdateSessionContent.dart';
import '../domains/messages/outgoing-messages/update-session/UpdateSessionMessage.dart';
import '../domains/messenger/SocketMessenger.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'NP+',
        theme: PartyHarderTheme.getLightTheme(),
        darkTheme: PartyHarderTheme.getDarkTheme(),
        home: AppContainer(
          title: 'NP+',
        ));
  }
}

class AppContainer extends StatefulWidget {
  final String title;
  AppContainer({Key key, @required this.title}) : super(key: key);

  @override
  _AppContainerState createState() => _AppContainerState();
}

class _AppContainerState extends State<AppContainer> with WidgetsBindingObserver {
  final serverTime = getIt.get<NPServerInfoStore>();

  final _messenger = getIt.get<SocketMessenger>();

  final _localUserService = getIt.get<LocalUserService>();

  final _npServerInfoStore = getIt.get<NPServerInfoStore>();
  final _playbackInfoStore = getIt.get<PlaybackInfoStore>();
  final _chatMessagesStore =
      getIt.get<ChatMessagesStore>();
  final _someoneIsTypingService = getIt.get<SomeoneIsTypingService>();
  final _localUserStore = getIt.get<LocalUserStore>();

  // Video info
  int _videoDuration = 655550;
  // TODO: capture video id

  // Connection info
  bool _hasJoinedSession = false;
  bool _isConnected = false;

  // Widget state
  bool _isAttemptingToJoinSessionFromText = false;
  bool _isAttemptingToJoinSessionFromQR = false;
  bool _shouldShowPartyPage = false;
  bool _isShowingChangelogDialog = false;
  TextEditingController _urlTextController = TextEditingController();
  bool _isKeyboardVisible = false;
  UniqueKey chatUniqueKey = UniqueKey();

  // Timers
  Timer _getServerTimeTimer;
  Timer _pingServerTimer;

  _AppContainerState() {
    _setupLocalUserListener();
    _dispatchShowChangelogIntent();
  }

  void _setupLocalUserListener() {
    _localUserStore.stream$.listen(_onLocalUserChanged);
  }

  void _onLocalUserChanged(LocalUser localUser) {
    if (_hasJoinedSession) {
      _sendBroadcastUserSettingsMessage(localUser);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_shouldShowPartyPage && !_isConnected) {
        _showToastMessage("Reconnecting...");
        _connectToServer();
      }
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    KeyboardVisibilityNotification().addNewListener(
        onChange: (isVisible) => _isKeyboardVisible = isVisible);

    _loadLastPartyUrl();
  }

  void _loadLastPartyUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _urlTextController.text = prefs.getString("lastPartyUrl") ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Stack(
        children: <Widget>[
          _shouldShowPartyPage ? _getPartyPage() : _getLandingPage(),
          Visibility(
              visible: !_isKeyboardVisible,
              child: SlidingUpPanel(
                backdropEnabled: true,
                parallaxEnabled: true,
                maxHeight: 400,
                minHeight: _shouldShowPartyPage ? 100 : 80,
                panelBuilder: (sc) => _panel(sc),
                isDraggable: _shouldShowPartyPage,
              ))
        ],
      ),
    );
  }

  Widget _panel(ScrollController scrollController) {
    return MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: Container(
          color: Theme.of(context).bottomAppBarColor,
          child: ListView(
            controller: scrollController,
            children: <Widget>[
              SizedBox(
                height: 12.0,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Visibility(
                    visible: _shouldShowPartyPage,
                    child: Container(
                      width: 30,
                      height: 5,
                      decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius:
                              BorderRadius.all(Radius.circular(12.0))),
                    ),
                  )
                ],
              ),
              SizedBox(
                height: 8,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Visibility(
                    visible: _shouldShowPartyPage,
                    child: CupertinoButton(
                      child: Text(
                        "Disconnect",
                        style: TextStyle(color: Theme.of(context).primaryColor),
                      ),
                      onPressed: () {
                        _onDisconnectButtonPressed();
                      },
                    ),
                  ),
                  StreamBuilder(
                      stream: _localUserStore.stream$,
                      initialData: LocalUser(),
                      builder: (context, localUserSnapshot) {
                        LocalUser localUser = localUserSnapshot.data;
                        return IconButton(
                          icon: SvgPicture.asset(
                              localUserSnapshot.data.icon != null
                                  ? 'assets/avatars/${localUser.icon}'
                                  : '',
                              height: 85),
                          onPressed: () {
                            _navigateToAccountSettings(context);
                          },
                        );
                      }),
                ],
              ),
              SizedBox(
                height: 5.0,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Visibility(
                    visible: _shouldShowPartyPage,
                    child: _getPlaybackControlButton(),
                  ),
                ],
              )
            ],
          ),
        ));
  }

  Widget _getLandingPage() {
    return SingleChildScrollView(
        child: Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: _getLandingPageWidgets(),
            )));
  }

  List<Widget> _getLandingPageWidgets() {
    List<Widget> widgets = List<Widget>();
    widgets.add(Padding(
      padding: EdgeInsets.all(6),
    ));
    widgets.add(
      Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Party URL",
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: 20),
          )),
    );
    widgets.add(Padding(
      padding: EdgeInsets.all(4),
    ));
    widgets.add(CupertinoTextField(
      textInputAction: TextInputAction.go,
      onSubmitted: (text) {
        _onConnectIntent();
      },
      controller: _urlTextController,
      placeholder: 'Enter URL',
      style: Theme.of(context).primaryTextTheme.body1,
      clearButtonMode: OverlayVisibilityMode.editing,
    ));
    widgets.add(Padding(
      padding: EdgeInsets.fromLTRB(50, 10, 50, 10),
      child: ProgressButton(
        child: Text(
          _isAttemptingToJoinSessionFromText ? "" : "Connect to Party",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: _onConnectIntent,
        buttonState: _isAttemptingToJoinSessionFromText
            ? ButtonState.inProgress
            : ButtonState.normal,
        backgroundColor: Theme.of(context).primaryColor,
        progressColor: Colors.white,
      ),
    ));
    widgets.add(Padding(
        padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
        child: Text(
          "OR",
          style: TextStyle(fontWeight: FontWeight.bold),
        )));
    widgets.add(Padding(
        padding: EdgeInsets.fromLTRB(0, 4, 0, 4),
        child: Align(
            alignment: Alignment.centerLeft,
            child:
                Text("1. Copy the link from Netflix Party on your computer"))));
    widgets.add(Padding(
        padding: EdgeInsets.fromLTRB(0, 4, 0, 4),
        child: Align(
            alignment: Alignment.centerLeft,
            child: Text("2. Visit the-qrcode-generator.com"))));
    widgets.add(Padding(
        padding: EdgeInsets.fromLTRB(0, 4, 0, 4),
        child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
                "3. Paste the link there to create a scannable QR code"))));
    widgets.add(Padding(
      padding: EdgeInsets.fromLTRB(50, 10, 50, 10),
      child: ProgressButton(
        child: Text(
          _isAttemptingToJoinSessionFromQR ? "" : "Scan QR Code",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: _onScanQRPressed,
        buttonState: _isAttemptingToJoinSessionFromQR
            ? ButtonState.inProgress
            : ButtonState.normal,
        backgroundColor: Theme.of(context).primaryColor,
        progressColor: Colors.white,
      ),
    ));
    return widgets;
  }

  Widget _getPartyPage() {
    Size currentScreenSize = MediaQuery.of(context).size;
    double screenRatio = currentScreenSize.height / currentScreenSize.width;
    return SizedBox(
        height: MediaQuery.of(context).size.height - (105 * screenRatio),
        child: Padding(
          padding: EdgeInsets.fromLTRB(6, 0, 6, 0),
          child: Chat(
            key: chatUniqueKey,
          ),
        ));
  }

  Widget _getPlaybackControlButton() {
    return StreamBuilder(
        stream: _playbackInfoStore.stream$,
        builder: (context, playbackInfoSnapshot) {
          return CupertinoButton(
              child: Icon(
                  playbackInfoSnapshot.hasData
                      ? (playbackInfoSnapshot.data.isPlaying
                          ? CupertinoIcons.pause_solid
                          : CupertinoIcons.play_arrow_solid)
                      : CupertinoIcons.play_arrow_solid,
                  size: 40),
              color: Theme.of(context).primaryColor,
              padding: EdgeInsets.fromLTRB(35, 0, 30, 4),
              minSize: 55,
              borderRadius: BorderRadius.circular(500),
              onPressed: playbackInfoSnapshot.hasData
                  ? (_playbackInfoStore.playbackInfo.isPlaying
                      ? _onPausePressed
                      : _onPlayPressed)
                  : _onPlayPressed);
        });
  }

  Future<void> _showChangelogDialog() async {
    await showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return ChangelogDialogFactory.getChangelogDialog(context);
        });
  }

  void _onConnectIntent() {
    setState(() {
      _isAttemptingToJoinSessionFromText = true;
    });
    _connectToServer();
  }

  void _onConnectFailed() {
    _showToastMessage("Invalid Link");
    setState(() {
      _isAttemptingToJoinSessionFromText = false;
      _isAttemptingToJoinSessionFromQR = false;
    });
  }

  void _onConnectionOpened() {
    setState(() {
      _isConnected = true;
    });
  }

  void _onConnectionClosed() {
    setState(() {
      _isConnected = false;
    });
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
    this._shouldShowPartyPage = false;
    this._clearState();
    _showToastMessage(errorMessage.errorMessage);
  }

  void _onUserIdMessageReceived(UserIdMessage userIdMessage) async {
    _localUserStore.updateLocalUser(LocalUser(
      username: _localUserStore.localUser.username,
      icon: _localUserStore.localUser.icon,
      id: userIdMessage.userId,
    ));
    await _localUserService.updateSavedLocalUser(_localUserStore.localUser);
    _sendGetServerTimeMessage();
  }

  void _onServerTimeMessageReceived(ServerTimeMessage serverTimeMessage) {
    if (!_hasJoinedSession) {
      _joinSession(_npServerInfoStore.npServerInfo.getSessionId());
    }
    _npServerInfoStore.updateServerTime(serverTimeMessage.serverTime);
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
        (Timer t) => _messenger.sendRawMessage("2"));
    setState(() {
      _shouldShowPartyPage = true;
    });
  }

  void _onUpdateMessageReceived(UpdateMessage updateMessage) {
    _playbackInfoStore.updatePlaybackInfo(PlaybackInfo(
        serverTimeAtLastVideoStateUpdate: updateMessage.lastKnownTimeUpdatedAt,
        lastKnownMoviePosition: updateMessage.lastKnownTime,
        isPlaying: updateMessage.state == VideoState.PLAYING));
    setState(() {
      _videoDuration = updateMessage.videoDuration;
    });
    _sendNotBufferingMessage();
  }

  void _onCatchupMessageReceived(
      VideoIdAndMessageCatchupMessage catchupMessage) {
    _playbackInfoStore.updatePlaybackInfo(PlaybackInfo(
        serverTimeAtLastVideoStateUpdate: catchupMessage.lastKnownTimeUpdatedAt,
        lastKnownMoviePosition: catchupMessage.lastKnownTime,
        isPlaying: catchupMessage.state == VideoState.PLAYING));
    _addChatMessages(catchupMessage.userMessages);
    _sendNotBufferingMessage();
  }

  void _onScanQRPressed() async {
    var result = await BarcodeScanner.scan();
    _urlTextController.text = result;
    _connectToServer();
    setState(() {
      _isAttemptingToJoinSessionFromQR = true;
    });
  }

  void _onDisconnectButtonPressed() {
    try {
      this._messenger.closeConnection();
      this._getServerTimeTimer.cancel();
      this._pingServerTimer.cancel();
    } on Exception {
      debugPrint("Failed to disconnect");
    }
    setState(() {
      _shouldShowPartyPage = false;
      _disconnect();
      _clearState();
    });
  }

  void _onPlayPressed() {
    _playbackInfoStore.updateAsPlaying();
    int estimatedServerTime = _npServerInfoStore.npServerInfo
        .getServerTimeAdjustedForTimeSinceLastServerTimeUpdate();
    _updateSessionContent(
        VideoState.PLAYING,
        _playbackInfoStore.playbackInfo.lastKnownMoviePosition,
        estimatedServerTime);
    _playbackInfoStore.updateServerTimeAtLastUpdate(estimatedServerTime);
  }

  void _onPausePressed() {
    _playbackInfoStore.updateAsPaused();
    _playbackInfoStore.updateLastKnownMoviePosition(
        _getVideoPositionAdjustedForTimeSinceLastVideoStateUpdate());
    int estimatedServerTime = _npServerInfoStore.npServerInfo
        .getServerTimeAdjustedForTimeSinceLastServerTimeUpdate();
    _updateSessionContent(
        VideoState.PAUSED,
        _playbackInfoStore.playbackInfo.lastKnownMoviePosition,
        estimatedServerTime);
    _playbackInfoStore.updateServerTimeAtLastUpdate(estimatedServerTime);
  }

  void _loadUserInfo() async {
    if (_shouldShowPartyPage) {
      _sendBroadcastUserSettingsMessage(_localUserStore.localUser);
    }
  }

  void _dispatchShowChangelogIntent() {
    Future.delayed(Duration(milliseconds: 300), () async {
      if (!_isShowingChangelogDialog) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String lastViewedChangelog =
            await prefs.getString("lastViewedChangelog");
        if (lastViewedChangelog != ChangelogService.getLatestVersion()) {
          _isShowingChangelogDialog = true;
          await _showChangelogDialog();
          _isShowingChangelogDialog = false;
        }
      }
    });
  }

  void _sendBroadcastUserSettingsMessage(LocalUser user) {
    _messenger.sendMessage(BroadcastUserSettingsMessage(
        BroadCastUserSettingsContent(UserSettings(
            true, UserAvatar.getNPName(user.icon), user.id, user.username))));
  }

  void _sendNotBufferingMessage() {
    BufferingContent bufferingContent = BufferingContent(false);
    _messenger.sendMessage(BufferingMessage(bufferingContent));
  }

  void _showToastMessage(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 35.0);
  }

  void _sendGetServerTimeMessage() {
    GetServerTimeContent getServerTimeContent = GetServerTimeContent("1.7.8");
    _messenger.sendMessage(GetServerTimeMessage(getServerTimeContent));
  }

  void _connectAndSetupListener(String serverId) {
    _messenger.establishConnection(
        "wss://$serverId.netflixparty.com/socket.io/?EIO=3&transport=websocket",
        _onReceivedStreamMessage,
        _onConnectionClosed,
        _onConnectionOpened);
  }

  void _updateLastJoinedPartyUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("lastPartyUrl", _urlTextController.text);
  }

  void _connectToServer() {
    _updateLastJoinedPartyUrl();
    _hasJoinedSession = false;
    _npServerInfoStore
        .updateNPServerInfo(NPServerInfo.fromUrl(url: _urlTextController.text));
    if (_npServerInfoStore.npServerInfo.isIncomplete()) {
      _onConnectFailed();
    }
    _connectAndSetupListener(_npServerInfoStore.npServerInfo.getServerId());
  }

  void _addChatMessages(List<UserMessage> userMessages) {
    _chatMessagesStore
        .pushNewChatMessages(userMessages.map((userMessage) {
      return ChatMessage(
          text: userMessage.body, user: _buildChatUser(userMessage));
    }).toList());
  }

  ChatUser _buildChatUser(UserMessage userMessage) {
    return ChatUser.fromJson({
      'uid': userMessage.userId,
      'name': userMessage.userNickname,
      'avatar': UserAvatar.formatIconName(userMessage.userIcon),
      'containerColor': AvatarColors.getColor(userMessage.userIcon)
    });
  }

  void _joinSession(String sessionIdForJoin) {
    UserSettings userSettings = UserSettings(
        true,
        _localUserStore.localUser.icon,
        _localUserStore.localUser.id,
        _localUserStore.localUser.username);
    JoinSessionContent joinSessionContent = JoinSessionContent(
        sessionIdForJoin, _localUserStore.localUser.id, userSettings);
    _messenger.sendMessage(JoinSessionMessage(joinSessionContent));
    _hasJoinedSession = true;
    setState(() {
      _isAttemptingToJoinSessionFromText = false;
      _isAttemptingToJoinSessionFromQR = false;
    });
  }

  void _disconnect() {
    _messenger.closeConnection();
    setState(() {
      _isConnected = false;
    });
  }

  void _clearState() {
    setState(() {
      if (_getServerTimeTimer != null) {
        _getServerTimeTimer.cancel();
        _getServerTimeTimer = null;
      }
      if (_pingServerTimer != null) {
        _pingServerTimer.cancel();
        _pingServerTimer = null;
      }
      _npServerInfoStore.updateServerTime(0);
      _playbackInfoStore.updateServerTimeAtLastUpdate(0);
      _playbackInfoStore.updateLastKnownMoviePosition(0);
      _hasJoinedSession = false;
      _isAttemptingToJoinSessionFromText = false;
      _isAttemptingToJoinSessionFromQR = false;
      _chatMessagesStore.pushNewChatMessages(List.from([]));
    });
  }

  void _navigateToAccountSettings(buildContext) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserSettingsPage()),
    );
    await _loadUserInfo();
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

  void _updateSessionContent(
      String mediaState, int videoPosition, int lastKnownTimeUpdatedAt) {
    _messenger.sendMessage(UpdateSessionMessage(UpdateSessionContent(
        videoPosition,
        lastKnownTimeUpdatedAt,
        mediaState,
        null,
        null,
        _videoDuration,
        false)));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disconnect();
    _clearState();
    super.dispose();
  }
}
