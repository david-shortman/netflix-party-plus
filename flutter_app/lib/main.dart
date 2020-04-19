import 'dart:async';
import 'dart:io';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:dash_chat/dash_chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutterapp/domains/messages/incoming-messages/ErrorMessage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:progress_button/progress_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/io.dart';

import 'pages/UserSettingsScreen.dart';
import 'domains/messages/SocketMessage.dart';
import 'domains/messages/incoming-messages/ReceivedMessage.dart';
import 'domains/messages/incoming-messages/ReceivedMessageUtility.dart';
import 'domains/messages/incoming-messages/SentMessageMessage.dart';
import 'domains/messages/incoming-messages/ServerTimeMessage.dart';
import 'domains/messages/incoming-messages/SidMessage.dart';
import 'domains/messages/incoming-messages/UpdateMessage.dart';
import 'domains/messages/incoming-messages/UserIdMessage.dart';
import 'domains/messages/incoming-messages/UserMessage.dart';
import 'domains/messages/incoming-messages/VideoIdAndMessageCatchupMessage.dart';
import 'domains/messages/outgoing-messages/broadcast-user-settings/BroadCastUserSettingsMessage.dart';
import 'domains/messages/outgoing-messages/broadcast-user-settings/BroadcastUserSettingsContent.dart';
import 'domains/messages/outgoing-messages/buffering/BufferingContent.dart';
import 'domains/messages/outgoing-messages/buffering/BufferingMessage.dart';
import 'domains/messages/outgoing-messages/chat-message/SendMessageBody.dart';
import 'domains/messages/outgoing-messages/chat-message/SendMessageContent.dart';
import 'domains/messages/outgoing-messages/chat-message/SendMessageMessage.dart';
import 'domains/messages/outgoing-messages/join-session/JoinSessionContent.dart';
import 'domains/messages/outgoing-messages/join-session/JoinSessionMessage.dart';
import 'domains/messages/outgoing-messages/join-session/UserSettings.dart';
import 'domains/messages/outgoing-messages/server-time/GetServerTimeContent.dart';
import 'domains/messages/outgoing-messages/server-time/GetServerTimeMessage.dart';
import 'domains/messages/outgoing-messages/update-session/UpdateSessionContent.dart';
import 'domains/messages/outgoing-messages/update-session/UpdateSessionMessage.dart';
import 'domains/messenger/Messenger.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Netflix Party Harder',
      theme: new ThemeData(
        primaryColor: Colors.redAccent,
      ),
      home:  MyHomePage(
        title: 'Netflix Party Harder',
      )
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  MyHomePage({Key key, @required this.title})
      : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  IOWebSocketChannel currentChannel;
  Messenger messenger = new Messenger();
  String userId;
  String sessionId;
  int currentServerTime = 0;
  int currentLocalTime = 0;
  int lastKnownMoviePosition = 0;
  bool sessionJoined = false;
  bool isAttemptingToJoinSessionFromText = false;
  bool isAttemptingToJoinSessionFromQR = false;
  SidMessage sidMessage;
  TextEditingController _urlTextController = TextEditingController();
  Timer serverTimeTimer;
  Timer pingTimer;
  String _username;
  String _icon;
  bool isPlaying = false;
  bool connected = false;
  int videoDuration = 655550;
  List<UserMessage> userMessages = new List();
  List<ChatMessage> chatMessages = new List();

  _MyHomePageState() {
    _loadUsernameAndIcon();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.red,
      ),
      body: connected ? _getConnectedWidget() : _getNotConnectedWidget(),
      bottomNavigationBar: _getBottomAppBarWidget(),
      floatingActionButton: Visibility(visible: connected, child: _getPlayControlButton()),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _getBottomAppBarWidget() {
    return BottomAppBar(
      child: new Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Visibility(
            visible: connected,
            child: IconButton(
              icon: Icon(Icons.power_settings_new),
              onPressed: () {
                disconnectButtonPressed();
              },
            ),),
          IconButton(
            icon: SvgPicture.asset('assets/avatars/${_icon ?? 'Alien.svg'}', height: 85),
            onPressed: () {
              goToAccountSettings(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _getNotConnectedWidget() {
    return SingleChildScrollView(child: Padding(padding: new EdgeInsets.all(10), child: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: getNotConnectedWidgets(),
    )));
  }

  Widget _getConnectedWidget() {
    return Padding(
      padding: new EdgeInsets.all(10),
      child: DashChat(
          scrollToBottom: false,
          messages: chatMessages,
          onSend: (message) {
            postMessageText(message.text);
          },
          user: ChatUser(
            name: _username,
            uid: userId,
            avatar: _icon,
          ),
        avatarBuilder: (chatUser) {
            debugPrint(chatUser.avatar);
            return new SvgPicture.asset('assets/avatars/${chatUser.avatar}', height: 35);
        },),
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

  _sendBroadcastUserSettingsMessage() {
    sendMessage(BroadcastUserSettingsMessage(BroadCastUserSettingsContent(UserSettings(true, _icon, userId, _username))));
  }

  void postMessageText(String messageText) {
    int currentTimeInMilliseconds = (new DateTime.now().millisecondsSinceEpoch);
    int millisecondsSinceLastUpdate = currentTimeInMilliseconds - currentLocalTime;
    int expectedServerTime = currentServerTime + millisecondsSinceLastUpdate;
    SendMessageContent sendMessageContent = new SendMessageContent(new SendMessageBody(messageText, false, expectedServerTime, userId, userId, _icon, _username));
    sendMessage(new SendMessageMessage(sendMessageContent));
  }

  void sendNotBufferingMessage() {
    BufferingContent bufferingContent = new BufferingContent(false);
    sendMessage(new BufferingMessage(bufferingContent));
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
          int sessionIdStart = _urlTextController.text.toString().indexOf(
              'npSessionId=');
          if (sessionIdStart >= 0) {
            int sessionIdEnd = _urlTextController.text.toString().indexOf(
                '&', sessionIdStart);
            if (sessionIdEnd > sessionIdStart) {
              sessionId = _urlTextController.text.toString().substring(
                  sessionIdStart + 12, sessionIdEnd);
            } else {
              sessionId =
                  _urlTextController.text.toString().substring(sessionIdStart + 12);
            }
          }
          int serverIdStart = _urlTextController.text.toString().indexOf('npServerId=');
          if (serverIdStart >= 0) {
            int serverIdEnd = _urlTextController.text.toString().indexOf(
                '&', serverIdStart);
            if (serverIdEnd > serverIdStart) {
              serverId = _urlTextController.text.toString().substring(
                  serverIdStart + 11, serverIdEnd);
            } else {
              serverId =
                  _urlTextController.text.toString().substring(serverIdStart + 11);
            }
          }
        } on Exception catch (e) {
          debugPrint("Error parsing URL: " + _urlTextController.text + e.toString());
        }
      }
      if ("" == serverId || "" == sessionId) {
        showToastMessage("Invalid Link");
        setState(() {
          sleep(new Duration(milliseconds: 1000));
          isAttemptingToJoinSessionFromText = false;
          isAttemptingToJoinSessionFromQR = false;
        });
        return;
      }
      debugPrint("ServerId: "+serverId);
      debugPrint("SessionId: "+sessionId);
      connectAndSetupListener(serverId);
  }

  void connectAndSetupListener(String serverId) {
    currentChannel = new IOWebSocketChannel.connect("wss://"+serverId+".netflixparty.com/socket.io/?EIO=3&transport=websocket");
    messenger.setChannel(currentChannel);
    currentChannel.stream.listen(
        _onReceivedStreamMessage,
        onError: (error, StackTrace stackTrace){
          debugPrint('onError');
        },
        onDone: (){
          debugPrint('Communication Closed');
        }
    );
  }

  void _onReceivedStreamMessage(message) {
    // TODO: clean up this method
    debugPrint('got $message');
    ReceivedMessage messageObj = ReceivedMessageUtility.fromString(message);
    if(messageObj is UserIdMessage) {
      userId = messageObj.userId;
      sendGetServerTimeMessage();
    } else if(messageObj is ServerTimeMessage) {
      if (!sessionJoined) {
        joinSession(userId, "Mobile User", sessionId);
      }
    } else if(messageObj is UpdateMessage) {
      lastKnownMoviePosition = messageObj.lastKnownTime;
      videoDuration = messageObj.videoDuration;
      currentServerTime = messageObj.lastKnownTimeUpdatedAt;
      currentLocalTime = (new DateTime.now().millisecondsSinceEpoch);
      debugPrint("last Known time - "+ messageObj.lastKnownTime.toString()+" at "+messageObj.lastKnownTimeUpdatedAt.toString());
      sendNotBufferingMessage();

      if(messageObj.state == "playing") {
        setState(() {
          this.isPlaying = true;
        });
      } else {
        setState(() {
          this.isPlaying = false;
        });
      }
    } else {
      if(messageObj is SidMessage) {
        SidMessage sidMessage = messageObj;
        this.sidMessage = sidMessage;
        if(serverTimeTimer != null) {
          serverTimeTimer.cancel();
          serverTimeTimer = null;
        }
        serverTimeTimer = Timer.periodic(Duration(milliseconds: 5000), (Timer t) => sendGetServerTimeMessage());
        if (pingTimer != null) {
          pingTimer.cancel();
          pingTimer = null;
        }
        pingTimer = Timer.periodic(Duration(milliseconds: sidMessage.pingInterval), (Timer t) => currentChannel.sink.add("2"));
        setState(() {
          connected = true;
        });
      }
      else if(messageObj is SentMessageMessage) {
        setState(() {
          this.userMessages.add(messageObj.userMessage);
          this.chatMessages.add(new ChatMessage(createdAt: DateTime.fromMillisecondsSinceEpoch(messageObj.userMessage.timestamp), text: messageObj.userMessage.body, user: new ChatUser.fromJson({
            'uid': messageObj.userMessage.userId,
            'name': messageObj.userMessage.userNickname,
            'avatar': messageObj.userMessage.userIcon
          })));
        });
      }
      else if(messageObj is VideoIdAndMessageCatchupMessage) {
        this.userMessages.addAll(messageObj.userMessages);
        this.chatMessages.addAll(messageObj.userMessages.map((userMessage) {
          return new ChatMessage(text: userMessage.body, user: new ChatUser.fromJson({
            'uid': userMessage.userId,
            'name': userMessage.userNickname,
            'avatar': userMessage.userIcon
          }));
        }));
        lastKnownMoviePosition = messageObj.lastKnownTime;
        currentServerTime = messageObj.lastKnownTimeUpdatedAt;
        currentLocalTime = (new DateTime.now().millisecondsSinceEpoch);
        debugPrint("last Known time - "+ messageObj.lastKnownTime.toString()+" at "+messageObj.lastKnownTimeUpdatedAt.toString());
        sendNotBufferingMessage();
        debugPrint(messageObj.state);
        setState(() {
          if(messageObj.state == "playing") {
            this.isPlaying = true;
          } else {
            this.isPlaying = false;
          }
        });
      }
      else if(messageObj is ErrorMessage) {
        this.connected = false;
        this.clearAllVariables();
        showToastMessage(messageObj.errorMessage);
      }
    }
  }

  void showToastMessage(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 35.0
    );
  }

  void joinSession(String userIdForJoin, String nickNameForJoin, String sessionIdForJoin) {
    UserSettings userSettings = new UserSettings(true, "Sailor Cat.svg", userIdForJoin, nickNameForJoin);
    JoinSessionContent joinSessionContent = new JoinSessionContent(sessionIdForJoin, userIdForJoin, userSettings);
    sendMessage(new JoinSessionMessage(joinSessionContent));
    sessionJoined = true;
    setState(() {
      isAttemptingToJoinSessionFromText = false;
      isAttemptingToJoinSessionFromQR = false;
    });
  }

  void sendGetServerTimeMessage() {
    GetServerTimeContent getServerTimeContent = new GetServerTimeContent("1.7.8");
    sendMessage(new GetServerTimeMessage(getServerTimeContent));
  }

  void sendMessage(SocketMessage message) {
    messenger.sendMessage(message);
  }

  void disconnect() {
    currentChannel.sink.close();
  }

  void clearAllVariables() {
    setState(() {
      if(serverTimeTimer != null) {
        serverTimeTimer.cancel();
        serverTimeTimer = null;
      }
      if(pingTimer != null) {
        pingTimer.cancel();
        pingTimer = null;
      }
      currentChannel = null;
      userId = null;
      sessionId = null;
      currentServerTime = 0;
      currentLocalTime = 0;
      lastKnownMoviePosition = 0;
      sessionJoined = false;
      isAttemptingToJoinSessionFromText = false;
      isAttemptingToJoinSessionFromQR = false;
      userMessages.clear();
      chatMessages.clear();

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
      new MaterialPageRoute(builder: (context) => UserSettingsScreen()),
    );
    _loadUsernameAndIcon();
  }

  List<Widget> getNotConnectedWidgets() {
    debugPrint('remove me');
    List<Widget> widgets = new List<Widget>();
    widgets.add(TextFormField(
      textInputAction: TextInputAction.go,
      onFieldSubmitted: _onSubmitPressedInUrlField,
      controller: _urlTextController,
      decoration: InputDecoration(labelText: 'Enter URL', suffixIcon: IconButton(icon: Icon(Icons.cancel), onPressed: () {
        WidgetsBinding.instance.addPostFrameCallback( (_) => _urlTextController.clear());
      },)),
    ));
    widgets.add(Padding(
      padding: new EdgeInsets.fromLTRB(50, 10, 50, 10),
      child: ProgressButton(
        child: Text(isAttemptingToJoinSessionFromText ? "" : "Connect", style: new TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
        onPressed: _onConnectPressed,
        buttonState: isAttemptingToJoinSessionFromText ? ButtonState.inProgress : ButtonState.normal,
        backgroundColor: Theme.of(context).primaryColor,
        progressColor: Colors.white,
      ),
    ));
    widgets.add(Padding(padding: new EdgeInsets.fromLTRB(0, 10, 0, 10), child: Text("OR")));
    widgets.add(Padding(padding: new EdgeInsets.fromLTRB(0, 4, 0, 4), child: Align(alignment: Alignment.centerLeft, child: Text("1. Copy the link from Netflix Party on your computer"))));
    widgets.add(Padding(padding: new EdgeInsets.fromLTRB(0, 4, 0, 4), child: Align(alignment: Alignment.centerLeft,child: Text("2. Visit the-qrcode-generator.com"))));
    widgets.add(Padding(padding: new EdgeInsets.fromLTRB(0, 4, 0, 4), child: Align(alignment: Alignment.centerLeft,child: Text("3. Paste the link there to create a scannable QR code"))));
    widgets.add(Padding(
      padding: new EdgeInsets.fromLTRB(50, 10, 50, 10),
      child: ProgressButton(
        child: Text(isAttemptingToJoinSessionFromQR ? "" : "Scan QR Code", style: new TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
        onPressed: _onScanQRPressed,
        buttonState: isAttemptingToJoinSessionFromQR ? ButtonState.inProgress : ButtonState.normal,
        backgroundColor: Theme.of(context).primaryColor,
        progressColor: Colors.white,
      ),
    ));
    return widgets;
  }

  void _onScanQRPressed() async {
    debugPrint('qr pressed');
    var result = await BarcodeScanner.scan();
    _urlTextController.text = result;
    _connectToServer();
    setState(() {
      isAttemptingToJoinSessionFromQR = true;
    });
    debugPrint(result);
  }

  void disconnectButtonPressed() {
    try {
      this.currentChannel.sink.close();
      this.serverTimeTimer.cancel();
      this.pingTimer.cancel();
    } on Exception {}
    setState(() {
      connected = false;
      disconnect();
      clearAllVariables();
    });
  }

  Widget _getPlayControlButton() {
    return FlatButton(
      color: Theme.of(context).primaryColor,
      shape: new CircleBorder(),
      onPressed: isPlaying ? _onPausePressed : _onPlayPressed,
      child: Icon(isPlaying ? Icons.pause : Icons.play_arrow, size: 50, color: Colors.white,),
    );
  }

  void _onPlayPressed() {
    debugPrint('sending play with movie time: ' + lastKnownMoviePosition.toString());
    int currentTimeInMilliseconds = (new DateTime.now().millisecondsSinceEpoch);
    int millisecondsSinceLastUpdate = currentTimeInMilliseconds - currentLocalTime;
    int expectedServerTime = currentServerTime + millisecondsSinceLastUpdate;
    this.currentServerTime = expectedServerTime;
    currentLocalTime = (new DateTime.now().millisecondsSinceEpoch);
    UpdateSessionContent updateSessionContent = new UpdateSessionContent(lastKnownMoviePosition, currentServerTime, "playing", null, null, videoDuration, false);
    sendMessage(new UpdateSessionMessage(updateSessionContent));
    setState(() {
      isPlaying = true;
    });
  }

  void _onPausePressed() {
    int currentTimeInMilliseconds = (new DateTime.now().millisecondsSinceEpoch);
    int millisecondsSinceLastUpdate = currentTimeInMilliseconds - currentLocalTime;
    int expectedMovieTime = lastKnownMoviePosition + millisecondsSinceLastUpdate;
    int expectedServerTime = currentServerTime + millisecondsSinceLastUpdate;

    currentServerTime = expectedServerTime;
    lastKnownMoviePosition = expectedMovieTime;
    currentLocalTime = (new DateTime.now().millisecondsSinceEpoch);

    debugPrint('sending pause with movie time: ' + expectedMovieTime.toString());
    UpdateSessionContent updateSessionContent = new UpdateSessionContent(lastKnownMoviePosition, currentServerTime, "paused", null, null, videoDuration, false);
    sendMessage(new UpdateSessionMessage(updateSessionContent));
    setState(() {
      isPlaying = false;
    });
  }
}

