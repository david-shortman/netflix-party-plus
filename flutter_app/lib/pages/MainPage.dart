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
import 'package:np_plus/playback/PlaybackInfo.dart';
import 'package:np_plus/theming/AppTheme.dart';
import 'package:np_plus/theming/AvatarColors.dart';
import 'package:np_plus/widgets/ChangelogDialogFactory.dart';
import 'package:np_plus/widgets/ChatStream.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:keyboard_visibility/keyboard_visibility.dart';
import 'package:progress_button/progress_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../domains/avatar/Avatar.dart';
import 'UserSettingsScreen.dart';
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
import '../domains/messages/outgoing-messages/chat-message/SendMessageBody.dart';
import '../domains/messages/outgoing-messages/chat-message/SendMessageContent.dart';
import '../domains/messages/outgoing-messages/chat-message/SendMessageMessage.dart';
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
        title: 'Netflix Party Harder',
        theme: PartyHarderTheme.getLightTheme(),
        darkTheme: PartyHarderTheme.getDarkTheme(),
        home: MainPage(
          title: 'Netflix Party Harder',
        ));
  }
}

class MainPage extends StatefulWidget {
  final String title;
  MainPage({Key key, @required this.title}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  SocketMessenger _messenger = SocketMessenger();

  LocalUser _user = LocalUser();

  NPServerInfo _npServerInfo;

  // Video info
  int _videoDuration = 655550;
  // TODO: capture video id

  PlaybackInfo playbackInfo = PlaybackInfo(
      localTimeAtLastUpdate: 0, lastKnownMoviePosition: 0, isPlaying: false);

  // Connection info
  bool _hasJoinedSession = false;
  bool _isConnected = false;
  String _userId;

  // Widget state
  bool _isAttemptingToJoinSessionFromText = false;
  bool _isAttemptingToJoinSessionFromQR = false;
  bool _shouldShowPartyPage = false;
  bool _isShowingChangelogDialog = false;
  TextEditingController _urlTextController = TextEditingController();
  TextEditingController _messageTextEditingController = TextEditingController();
  String _messageInputText;
  ScrollController _chatStreamScrollController = ScrollController();
  List<ChatMessage> _chatMessages = List();
  bool _isKeyboardVisible = false;

  Timer _getServerTimeTimer;
  Timer _pingServerTimer;

  // Constant
  ChatMessage _someoneIsTypingMessage = ChatMessage(
      text: "Someone is typing...", user: ChatUser(uid: "10", avatar: ""));

  _MainPageState() {
    _loadUserInfo();
    _dispatchShowChangelog();
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
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Stack(
        children: <Widget>[
          _shouldShowPartyPage
              ? _getPartyPage()
              : _getLandingPage(),
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
                  IconButton(
                    icon: SvgPicture.asset(
                        _user.icon != null
                            ? 'assets/avatars/${_user.icon}'
                            : '',
                        height: 85),
                    onPressed: () {
                      _navigateToAccountSettings(context);
                    },
                  ),
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
                    child: _getPlayControlButton(),
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
      onSubmitted: _onSubmitPressedInUrlField,
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
        onPressed: _onConnectPressed,
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

  void _setChatInputTextState(String text) {
    setState(() {
      _messageInputText = text;
    });
  }

  Widget _getPartyPage() {
    Size currentScreenSize = MediaQuery.of(context).size;
    double screenRatio = currentScreenSize.height / currentScreenSize.width;
    return SizedBox(
      height: MediaQuery.of(context).size.height - (105 * screenRatio),
      child: ChatStream.getChatStream(
          setTextState: _setChatInputTextState,
          text: _messageInputText,
          context: context,
          messages: _chatMessages,
          onSend: (message) {
            _postMessageText(message.text);
          },
          userSettings:
              UserSettings(false, _user.icon, _user.userId, _user.username),
          scrollController: _chatStreamScrollController,
          textEditingController: _messageTextEditingController,
          messenger: _messenger),
    );
  }

  Widget _getPlayControlButton() {
    return CupertinoButton(
        child: Icon(
            playbackInfo.isPlaying
                ? CupertinoIcons.pause_solid
                : CupertinoIcons.play_arrow_solid,
            size: 40),
        color: Theme.of(context).primaryColor,
        padding: EdgeInsets.fromLTRB(35, 0, 30, 4),
        minSize: 55,
        borderRadius: BorderRadius.circular(500),
        onPressed: playbackInfo.isPlaying ? _onPausePressed : _onPlayPressed);
  }

  Future<void> _showChangelogDialog() async {
    await showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return ChangelogDialogFactory.getChangelogDialog(context);
        });
  }

  void _onSubmitPressedInUrlField(String s) {
    _onConnectPressed();
  }

  void _onConnectPressed() {
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

  void _onUserIdMessageReceived(UserIdMessage userIdMessage) {
    _userId = userIdMessage.userId;
    _user.userId = _userId;
    _sendGetServerTimeMessage();
  }

  void _onServerTimeMessageReceived(ServerTimeMessage serverTimeMessage) {
    if (!_hasJoinedSession) {
      _joinSession(_npServerInfo.getSessionId());
    }
    _npServerInfo.currentServerTime = serverTimeMessage.serverTime;
  }

  void _onSetPresenceMessageReceived(SetPresenceMessage setPresenceMessage) {
    setState(() {
      if (setPresenceMessage.anyoneTyping &&
          !_chatMessages.contains(_someoneIsTypingMessage)) {
        _chatMessages.add(_someoneIsTypingMessage);
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _scrollToBottomOfChatStream());
      } else {
        _chatMessages.remove(_someoneIsTypingMessage);
      }
    });
  }

  void _onSentMessageMessageReceived(SentMessageMessage sentMessageMessage) {
    setState(() {
      this._chatMessages.add(ChatMessage(
          createdAt: DateTime.fromMillisecondsSinceEpoch(
              sentMessageMessage.userMessage.timestamp),
          text: sentMessageMessage.userMessage.body,
          user: _buildChatUser(sentMessageMessage.userMessage)));
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollToBottomOfChatStream());
    });
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
    playbackInfo.lastKnownMoviePosition = updateMessage.lastKnownTime;
    _videoDuration = updateMessage.videoDuration;
    _npServerInfo.currentServerTime = updateMessage.lastKnownTimeUpdatedAt;
    playbackInfo.localTimeAtLastUpdate =
        _getCurrentTimeMillisecondsSinceEpoch();

    _sendNotBufferingMessage();

    setState(() {
      this.playbackInfo.isPlaying = updateMessage.state == VideoState.PLAYING;
    });
  }

  void _onCatchupMessageReceived(
      VideoIdAndMessageCatchupMessage catchupMessage) {
    _addChatMessages(catchupMessage.userMessages);

    WidgetsBinding.instance
        .addPostFrameCallback((_) => _scrollToBottomOfChatStream());

    playbackInfo.lastKnownMoviePosition = catchupMessage.lastKnownTime;
    _npServerInfo.currentServerTime = catchupMessage.lastKnownTimeUpdatedAt;
    playbackInfo.localTimeAtLastUpdate =
        _getCurrentTimeMillisecondsSinceEpoch();

    _sendNotBufferingMessage();

    setState(() {
      this.playbackInfo.isPlaying = catchupMessage.state == VideoState.PLAYING;
    });
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
    _npServerInfo.currentServerTime =
        _getCurrentServerTimeAdjustedForCurrentTime();
    _updateSessionContent(VideoState.PLAYING,
        playbackInfo.lastKnownMoviePosition, _npServerInfo.currentServerTime);
    playbackInfo.localTimeAtLastUpdate =
        _getCurrentTimeMillisecondsSinceEpoch();
  }

  void _onPausePressed() {
    playbackInfo.lastKnownMoviePosition =
        _getLastKnownMoviePositionAdjustedForCurrentTime();
    _npServerInfo.currentServerTime =
        _getCurrentServerTimeAdjustedForCurrentTime();
    _updateSessionContent(VideoState.PAUSED,
        playbackInfo.lastKnownMoviePosition, _npServerInfo.currentServerTime);
    playbackInfo.localTimeAtLastUpdate =
        _getCurrentTimeMillisecondsSinceEpoch();
  }

  void _loadUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      _user = LocalUser(
          username: prefs.getString('username') ?? "Mobile User",
          icon: prefs.getString('userIcon') ?? "Batman.svg",
          userId: _userId);
      if (_shouldShowPartyPage) {
        _sendBroadcastUserSettingsMessage(_user);
      }
    });
  }

  void _dispatchShowChangelog() {
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
        BroadCastUserSettingsContent(UserSettings(true,
            UserAvatar.getNPName(user.icon), user.userId, user.username))));
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

  void _postMessageText(String messageText) {
    _messenger.sendMessage(SendMessageMessage(SendMessageContent(
        SendMessageBody(
            messageText,
            false,
            _getCurrentServerTimeAdjustedForCurrentTime(),
            _user.userId,
            _user.userId,
            _user.icon,
            _user.username))));
  }

  void _connectAndSetupListener(String serverId) {
    _messenger.establishConnection("wss://$serverId.netflixparty.com/socket.io/?EIO=3&transport=websocket", _onReceivedStreamMessage, _onConnectionClosed, _onConnectionOpened);
  }

  void _updateLastJoinedPartyUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("lastPartyUrl", _urlTextController.text);
  }

  void _connectToServer() {
    _updateLastJoinedPartyUrl();
    _hasJoinedSession = false;
    _npServerInfo = NPServerInfo(url: _urlTextController.text);
    if (_npServerInfo.isIncomplete()) {
      _onConnectFailed();
    }
    _connectAndSetupListener(_npServerInfo.getServerId());
  }

  void _addChatMessages(List<UserMessage> userMessages) {
    _chatMessages.addAll(userMessages.map((userMessage) {
      return ChatMessage(
          text: userMessage.body, user: _buildChatUser(userMessage));
    }));
  }

  ChatUser _buildChatUser(UserMessage userMessage) {
    return ChatUser.fromJson({
      'uid': userMessage.userId,
      'name': userMessage.userNickname,
      'avatar': UserAvatar.formatIconName(userMessage.userIcon),
      'containerColor': AvatarColors.getColor(userMessage.userIcon)
    });
  }

  void _scrollToBottomOfChatStream() {
    _chatStreamScrollController.animateTo(
        _chatStreamScrollController.position.maxScrollExtent + 5,
        duration: Duration(milliseconds: 300),
        curve: Curves.linear);
  }

  void _joinSession(String sessionIdForJoin) {
    UserSettings userSettings =
        UserSettings(true, _user.icon, _user.userId, _user.username);
    JoinSessionContent joinSessionContent =
        JoinSessionContent(sessionIdForJoin, _user.userId, userSettings);
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
      _npServerInfo.currentServerTime = 0;
      playbackInfo.localTimeAtLastUpdate = 0;
      playbackInfo.lastKnownMoviePosition = 0;
      _hasJoinedSession = false;
      _isAttemptingToJoinSessionFromText = false;
      _isAttemptingToJoinSessionFromQR = false;
      _chatMessages.clear();
    });
  }

  void _navigateToAccountSettings(buildContext) async {
    print("go to account settings");
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserSettingsScreen()),
    );
    _loadUserInfo();
  }

  int _getCurrentServerTimeAdjustedForCurrentTime() {
    return _npServerInfo.currentServerTime + _getMillisecondsSinceLastUpdate();
  }

  int _getCurrentTimeMillisecondsSinceEpoch() {
    return DateTime.now().millisecondsSinceEpoch;
  }

  int _getMillisecondsSinceLastUpdate() {
    return _getCurrentTimeMillisecondsSinceEpoch() -
        playbackInfo.localTimeAtLastUpdate;
  }

  int _getLastKnownMoviePositionAdjustedForCurrentTime() {
    return playbackInfo.lastKnownMoviePosition +
        _getMillisecondsSinceLastUpdate();
  }

  void _updateSessionContent(
      String mediaState, int videoPosition, int currentServerTime) {
    UpdateSessionContent updateSessionContent = UpdateSessionContent(
        videoPosition,
        currentServerTime,
        mediaState,
        null,
        null,
        _videoDuration,
        false);
    _messenger.sendMessage(UpdateSessionMessage(updateSessionContent));
    setState(() {
      playbackInfo.isPlaying = mediaState == VideoState.PLAYING;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disconnect();
    _clearState();
    super.dispose();
  }
}
