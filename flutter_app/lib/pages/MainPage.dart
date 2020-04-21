import 'dart:async';
import 'dart:io';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:dash_chat/dash_chat.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutterapp/changelog/ChangelogService.dart';
import 'package:flutterapp/domains/messages/incoming-messages/ErrorMessage.dart';
import 'package:flutterapp/domains/messages/incoming-messages/SetPresenceMessage.dart';
import 'package:flutterapp/theming/AppTheme.dart';
import 'package:flutterapp/theming/AvatarColors.dart';
import 'package:flutterapp/widgets/ChangelogDialogFactory.dart';
import 'package:flutterapp/widgets/ChatStream.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:keyboard_visibility/keyboard_visibility.dart';
import 'package:progress_button/progress_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:web_socket_channel/io.dart';

import '../domains/avatar/Avatar.dart';
import 'UserSettingsScreen.dart';
import '../domains/messages/SocketMessage.dart';
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
import '../domains/messenger/Messenger.dart';

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

class _MainPageState extends State<MainPage> {
  IOWebSocketChannel currentChannel;
  Messenger messenger = Messenger();
  String _userId;
  String sessionId;
  int currentServerTime = 0;
  int currentLocalTime = 0;
  int lastKnownMoviePosition = 0;
  bool sessionJoined = false;
  bool isAttemptingToJoinSessionFromText = false;
  bool isAttemptingToJoinSessionFromQR = false;
  SidMessage sidMessage;
  TextEditingController _urlTextController = TextEditingController();
  ScrollController _chatStreamScrollController = ScrollController();
  Timer serverTimeTimer;
  Timer pingTimer;
  String _username;
  String _icon;
  bool isPlaying = false;
  bool connected = false;
  bool _isShowingChangelogDialog = false;
  int videoDuration = 655550;
  List<UserMessage> userMessages = List();
  List<ChatMessage> _chatMessages = List();
  ChatMessage _someoneIsTypingMessage = ChatMessage(
      text: "Someone is typing...", user: ChatUser(uid: "10", avatar: ""));
  bool _isKeyboardVisible = false;
  TextEditingController _messageTextEditingController = TextEditingController();
  String messageInputText;

  _MainPageState() {
    _loadUsernameAndIcon();
    _dispatchShowChangelogIntent();
  }

  @override
  void initState() {
    super.initState();
    KeyboardVisibilityNotification().addNewListener(
        onChange: (isVisible) => _isKeyboardVisible = isVisible);
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
          connected ? _getConnectedWidget() : _getNotConnectedWidget(),
          Visibility(
              visible: !_isKeyboardVisible,
              child: SlidingUpPanel(
                backdropEnabled: true,
                parallaxEnabled: true,
                maxHeight: 400,
                minHeight: connected ? 100 : 80,
                panelBuilder: (sc) => _panel(sc),
                isDraggable: connected,
              ))
        ],
      ),
    );
  }

  Widget _panel(ScrollController sc) {
    return MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: Container(
          color: Colors.black87,
          child: ListView(
            controller: sc,
            children: <Widget>[
              SizedBox(
                height: 12.0,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Visibility(
                    visible: connected,
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
                    visible: connected,
                    child: CupertinoButton(
                      child: Text(
                        "Disconnect",
                        style: TextStyle(color: Theme.of(context).primaryColor),
                      ),
                      onPressed: () {
                        disconnectButtonPressed();
                      },
                    ),
                  ),
                  IconButton(
                    icon: SvgPicture.asset(
                        _icon != null ? 'assets/avatars/$_icon' : '',
                        height: 85),
                    onPressed: () {
                      goToAccountSettings(context);
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
                    visible: connected,
                    child: _getPlayControlButton(),
                  ),
                ],
              )
            ],
          ),
        ));
  }

  Widget _getNotConnectedWidget() {
    return SingleChildScrollView(
        child: Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: getNotConnectedWidgets(),
            )));
  }

  void _setTextState(String text) {
    setState(() {
      messageInputText = text;
    });
  }

  Widget _getConnectedWidget() {
    Size currentScreenSize = MediaQuery.of(context).size;
    double screenRatio = currentScreenSize.height / currentScreenSize.width;
    return SizedBox(
      height: MediaQuery.of(context).size.height - (105 * screenRatio),
      child: ChatStream.getChatStream(
          setTextState: _setTextState,
          text: messageInputText,
          context: context,
          messages: _chatMessages,
          onSend: (message) {
            postMessageText(message.text);
          },
          userSettings: UserSettings(false, _icon, _userId, _username),
          scrollController: _chatStreamScrollController,
          textEditingController: _messageTextEditingController,
          messenger: messenger),
    );
  }

  _loadUsernameAndIcon() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      _username = (prefs.getString('username') ?? "");
      _icon = (prefs.getString('userIcon') ?? "");
      if (_username == "") {
        _username = "Mobile User";
        prefs.setString("username", _username);
      }
      if (_icon == "") {
        _icon = "Batman.svg";
        prefs.setString("userIcon", _icon);
      }
    });
    print("_username is now " + _username);
    print("_icon is now " + _icon);
    if (connected) {
      _sendBroadcastUserSettingsMessage();
    }
  }

  _dispatchShowChangelogIntent() {
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

  _sendBroadcastUserSettingsMessage() {
    sendMessage(BroadcastUserSettingsMessage(BroadCastUserSettingsContent(
        UserSettings(true, _icon, _userId, _username))));
  }

  void postMessageText(String messageText) {
    int currentTimeInMilliseconds = (DateTime.now().millisecondsSinceEpoch);
    int millisecondsSinceLastUpdate =
        currentTimeInMilliseconds - currentLocalTime;
    int expectedServerTime = currentServerTime + millisecondsSinceLastUpdate;
    SendMessageContent sendMessageContent = SendMessageContent(SendMessageBody(
        messageText,
        false,
        expectedServerTime,
        _userId,
        _userId,
        _icon,
        _username));
    sendMessage(SendMessageMessage(sendMessageContent));
  }

  void sendNotBufferingMessage() {
    BufferingContent bufferingContent = BufferingContent(false);
    sendMessage(BufferingMessage(bufferingContent));
  }

  void _onSubmitPressedInUrlField(String s) {
    _onConnectPressed();
  }

  void _onConnectPressed() {
    setState(() {
      isAttemptingToJoinSessionFromText = true;
    });
    _connectToServer();
  }

  void _connectToServer() {
    sessionJoined = false;
    sessionId = "";
    String serverId = "";
    int varStart = _urlTextController.text.toString().indexOf('?');
    if (varStart >= 0) {
      try {
        int sessionIdStart =
            _urlTextController.text.toString().indexOf('npSessionId=');
        if (sessionIdStart >= 0) {
          int sessionIdEnd =
              _urlTextController.text.toString().indexOf('&', sessionIdStart);
          if (sessionIdEnd > sessionIdStart) {
            sessionId = _urlTextController.text
                .toString()
                .substring(sessionIdStart + 12, sessionIdEnd);
          } else {
            sessionId = _urlTextController.text
                .toString()
                .substring(sessionIdStart + 12);
          }
        }
        int serverIdStart =
            _urlTextController.text.toString().indexOf('npServerId=');
        if (serverIdStart >= 0) {
          int serverIdEnd =
              _urlTextController.text.toString().indexOf('&', serverIdStart);
          if (serverIdEnd > serverIdStart) {
            serverId = _urlTextController.text
                .toString()
                .substring(serverIdStart + 11, serverIdEnd);
          } else {
            serverId = _urlTextController.text
                .toString()
                .substring(serverIdStart + 11);
          }
        }
      } on Exception catch (e) {
        debugPrint(
            "Error parsing URL: " + _urlTextController.text + e.toString());
      }
    }
    if ("" == serverId || "" == sessionId) {
      showToastMessage("Invalid Link");
      setState(() {
        sleep(Duration(milliseconds: 1000));
        isAttemptingToJoinSessionFromText = false;
        isAttemptingToJoinSessionFromQR = false;
      });
      return;
    }
    debugPrint("ServerId: " + serverId);
    debugPrint("SessionId: " + sessionId);
    connectAndSetupListener(serverId);
  }

  void connectAndSetupListener(String serverId) {
    currentChannel = IOWebSocketChannel.connect("wss://" +
        serverId +
        ".netflixparty.com/socket.io/?EIO=3&transport=websocket");
    messenger.setChannel(currentChannel);
    currentChannel.stream.listen(_onReceivedStreamMessage,
        onError: (error, StackTrace stackTrace) {
      debugPrint('onError');
    }, onDone: () {
      debugPrint('Communication Closed');
    });
  }

  void _onReceivedStreamMessage(message) {
    // TODO: clean up this method
    debugPrint('got $message');
    ReceivedMessage messageObj = ReceivedMessageUtility.fromString(message);
    if (messageObj is UserIdMessage) {
      _userId = messageObj.userId;
      sendGetServerTimeMessage();
    } else if (messageObj is ServerTimeMessage) {
      if (!sessionJoined) {
        joinSession(sessionId);
      }
    } else if (messageObj is SetPresenceMessage) {
      if (messageObj.anyoneTyping) {
        if (!_chatMessages.contains(_someoneIsTypingMessage)) {
          debugPrint("adding someone typing message");
          setState(() {
            _chatMessages.add(_someoneIsTypingMessage);
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _scrollToBottomOfChatStream());
          });
        }
      } else {
        setState(() {
          _chatMessages.remove(_someoneIsTypingMessage);
        });
      }
    } else if (messageObj is UpdateMessage) {
      lastKnownMoviePosition = messageObj.lastKnownTime;
      videoDuration = messageObj.videoDuration;
      currentServerTime = messageObj.lastKnownTimeUpdatedAt;
      currentLocalTime = (DateTime.now().millisecondsSinceEpoch);
      debugPrint("last Known time - " +
          messageObj.lastKnownTime.toString() +
          " at " +
          messageObj.lastKnownTimeUpdatedAt.toString());
      sendNotBufferingMessage();

      if (messageObj.state == "playing") {
        setState(() {
          this.isPlaying = true;
        });
      } else {
        setState(() {
          this.isPlaying = false;
        });
      }
    } else {
      if (messageObj is SidMessage) {
        SidMessage sidMessage = messageObj;
        this.sidMessage = sidMessage;
        if (serverTimeTimer != null) {
          serverTimeTimer.cancel();
          serverTimeTimer = null;
        }
        serverTimeTimer = Timer.periodic(Duration(milliseconds: 5000),
            (Timer t) => sendGetServerTimeMessage());
        if (pingTimer != null) {
          pingTimer.cancel();
          pingTimer = null;
        }
        pingTimer = Timer.periodic(
            Duration(milliseconds: sidMessage.pingInterval),
            (Timer t) => currentChannel.sink.add("2"));
        setState(() {
          connected = true;
        });
      } else if (messageObj is SentMessageMessage) {
        setState(() {
          this.userMessages.add(messageObj.userMessage);
          this._chatMessages.add(ChatMessage(
              createdAt: DateTime.fromMillisecondsSinceEpoch(
                  messageObj.userMessage.timestamp),
              text: messageObj.userMessage.body,
              user: _buildChatUser(messageObj.userMessage)));
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _scrollToBottomOfChatStream());
        });
      } else if (messageObj is VideoIdAndMessageCatchupMessage) {
        this.userMessages.addAll(messageObj.userMessages);
        this._chatMessages.addAll(messageObj.userMessages.map((userMessage) {
          return ChatMessage(
              text: userMessage.body, user: _buildChatUser(userMessage));
        }));
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _scrollToBottomOfChatStream());
        lastKnownMoviePosition = messageObj.lastKnownTime;
        currentServerTime = messageObj.lastKnownTimeUpdatedAt;
        currentLocalTime = (DateTime.now().millisecondsSinceEpoch);
        debugPrint("last Known time - " +
            messageObj.lastKnownTime.toString() +
            " at " +
            messageObj.lastKnownTimeUpdatedAt.toString());
        sendNotBufferingMessage();
        debugPrint(messageObj.state);
        setState(() {
          if (messageObj.state == "playing") {
            this.isPlaying = true;
          } else {
            this.isPlaying = false;
          }
        });
      } else if (messageObj is ErrorMessage) {
        this.connected = false;
        this.clearAllVariables();
        showToastMessage(messageObj.errorMessage);
      }
    }
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

  void showToastMessage(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 35.0);
  }

  void joinSession(String sessionIdForJoin) {
    UserSettings userSettings = UserSettings(true, _icon, _userId, _username);
    JoinSessionContent joinSessionContent =
        JoinSessionContent(sessionIdForJoin, _userId, userSettings);
    sendMessage(JoinSessionMessage(joinSessionContent));
    sessionJoined = true;
    setState(() {
      isAttemptingToJoinSessionFromText = false;
      isAttemptingToJoinSessionFromQR = false;
    });
  }

  void sendGetServerTimeMessage() {
    GetServerTimeContent getServerTimeContent = GetServerTimeContent("1.7.8");
    sendMessage(GetServerTimeMessage(getServerTimeContent));
  }

  void sendMessage(SocketMessage message) {
    messenger.sendMessage(message);
  }

  void disconnect() {
    currentChannel.sink.close();
  }

  void clearAllVariables() {
    setState(() {
      if (serverTimeTimer != null) {
        serverTimeTimer.cancel();
        serverTimeTimer = null;
      }
      if (pingTimer != null) {
        pingTimer.cancel();
        pingTimer = null;
      }
      currentChannel = null;
      _userId = null;
      sessionId = null;
      currentServerTime = 0;
      currentLocalTime = 0;
      lastKnownMoviePosition = 0;
      sessionJoined = false;
      isAttemptingToJoinSessionFromText = false;
      isAttemptingToJoinSessionFromQR = false;
      userMessages.clear();
      _chatMessages.clear();
    });
  }

  @override
  void dispose() {
    debugPrint("Disposing...");
    disconnect();
    clearAllVariables();
    super.dispose();
  }

  //WIDGET FUNCTIONS

  goToAccountSettings(buildContext) async {
    print("go to account settings");
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserSettingsScreen()),
    );
    _loadUsernameAndIcon();
  }

  List<Widget> getNotConnectedWidgets() {
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
          isAttemptingToJoinSessionFromText ? "" : "Connect to Party",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: _onConnectPressed,
        buttonState: isAttemptingToJoinSessionFromText
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
          isAttemptingToJoinSessionFromQR ? "" : "Scan QR Code",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: _onScanQRPressed,
        buttonState: isAttemptingToJoinSessionFromQR
            ? ButtonState.inProgress
            : ButtonState.normal,
        backgroundColor: Theme.of(context).primaryColor,
        progressColor: Colors.white,
      ),
    ));
    return widgets;
  }

  void _onScanQRPressed() async {
    var result = await BarcodeScanner.scan();
    _urlTextController.text = result;
    _connectToServer();
    setState(() {
      isAttemptingToJoinSessionFromQR = true;
    });
  }

  void disconnectButtonPressed() {
    try {
      this.currentChannel.sink.close();
      this.serverTimeTimer.cancel();
      this.pingTimer.cancel();
    } on Exception {
      debugPrint("Failed to disconnect");
    }
    setState(() {
      connected = false;
      disconnect();
      clearAllVariables();
    });
  }

  Widget _getPlayControlButton() {
    return CupertinoButton(
        child: Icon(
            isPlaying
                ? CupertinoIcons.pause_solid
                : CupertinoIcons.play_arrow_solid,
            size: 40),
        color: Theme.of(context).primaryColor,
        padding: EdgeInsets.fromLTRB(35, 0, 30, 4),
        minSize: 55,
        borderRadius: BorderRadius.circular(500),
        onPressed: isPlaying ? _onPausePressed : _onPlayPressed);
  }

  void _onPlayPressed() {
    debugPrint(
        'sending play with movie time: ' + lastKnownMoviePosition.toString());
    int currentTimeInMilliseconds = (DateTime.now().millisecondsSinceEpoch);
    int millisecondsSinceLastUpdate =
        currentTimeInMilliseconds - currentLocalTime;
    int expectedServerTime = currentServerTime + millisecondsSinceLastUpdate;
    this.currentServerTime = expectedServerTime;
    currentLocalTime = (DateTime.now().millisecondsSinceEpoch);
    UpdateSessionContent updateSessionContent = UpdateSessionContent(
        lastKnownMoviePosition,
        currentServerTime,
        "playing",
        null,
        null,
        videoDuration,
        false);
    sendMessage(UpdateSessionMessage(updateSessionContent));
    setState(() {
      isPlaying = true;
    });
  }

  void _onPausePressed() {
    int currentTimeInMilliseconds = DateTime.now().millisecondsSinceEpoch;
    int millisecondsSinceLastUpdate =
        currentTimeInMilliseconds - currentLocalTime;
    int expectedMovieTime =
        lastKnownMoviePosition + millisecondsSinceLastUpdate;
    int expectedServerTime = currentServerTime + millisecondsSinceLastUpdate;

    currentServerTime = expectedServerTime;
    lastKnownMoviePosition = expectedMovieTime;
    currentLocalTime = (DateTime.now().millisecondsSinceEpoch);

    debugPrint(
        'sending pause with movie time: ' + expectedMovieTime.toString());
    UpdateSessionContent updateSessionContent = UpdateSessionContent(
        lastKnownMoviePosition,
        currentServerTime,
        "paused",
        null,
        null,
        videoDuration,
        false);
    sendMessage(UpdateSessionMessage(updateSessionContent));
    setState(() {
      isPlaying = false;
    });
  }

  Future<void> _showChangelogDialog() async {
    await showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return ChangelogDialogFactory.getChangelogDialog(context);
        });
  }
}
