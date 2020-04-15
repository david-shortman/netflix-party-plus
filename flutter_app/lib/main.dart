import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/io.dart';

import 'UserSettingsScreen.dart';
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
      title: 'Netflix Party',
      home:  MyHomePage(
        title: 'Netflix Party',
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
  String userId = null;
  String sessionId = null;
  int currentServerTime = 0;
  int currentLocalTime = 0;
  int lastKnownMoviePosition = 0;
  bool sessionJoined = false;
  SidMessage sidMessage;
  TextEditingController _controller = TextEditingController();
  TextEditingController _messageController = TextEditingController();
  Timer serverTimeTimer;
  Timer pingTimer;
  String _username;
  String _icon;
  bool isPlaying = false;
  bool connected = false;
  int videoDuration = 655550;
  List<UserMessage> userMessages = new List();

  _MyHomePageState() {
    _loadUsernameAndIcon();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: getActionIcons(context),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: getWidgets(),
        )),
      ),
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
  
  List<Widget> getWidgets() {
    if(!connected) {
      return getNotConnectedWidgets();
    } else {
      return getConnectedWidgets();
    }
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

  void connectToServer() {
      sessionJoined = false;
      sessionId = "";
      String serverId = "";
      int varStart = _controller.text.toString().indexOf('?');
      if (varStart >= 0) {
        int sessionIdStart = _controller.text.toString().indexOf(
            'npSessionId=');
        if (sessionIdStart >= 0) {
          int sessionIdEnd = _controller.text.toString().indexOf(
              '&', sessionIdStart);
          if (sessionIdEnd > sessionIdStart) {
            sessionId = _controller.text.toString().substring(
                sessionIdStart + 12, sessionIdEnd);
          } else {
            sessionId =
                _controller.text.toString().substring(sessionIdStart + 12);
          }
        }
        int serverIdStart = _controller.text.toString().indexOf('npServerId=');
        if (serverIdStart >= 0) {
          int serverIdEnd = _controller.text.toString().indexOf(
              '&', serverIdStart);
          if (serverIdEnd > serverIdStart) {
            serverId = _controller.text.toString().substring(
                serverIdStart + 11, serverIdEnd);
          } else {
            serverId =
                _controller.text.toString().substring(serverIdStart + 11);
          }
        }
      }
      debugPrint("ServerId: "+serverId);
      debugPrint("SessionId: "+sessionId);
      connectAndSetupListener(serverId);
  }
  
  void sendMessageToChat() {
    postMessageText(_messageController.text);
    setState(() {
      _messageController.text = "";
    });
  }

  void connectAndSetupListener(String serverId) {
    currentChannel = new IOWebSocketChannel.connect("wss://"+serverId+".netflixparty.com/socket.io/?EIO=3&transport=websocket");
    messenger.setChannel(currentChannel);
    currentChannel.stream.listen(
            (message){
          debugPrint('got $message');
          ReceivedMessage messageObj = ReceivedMessageUtility.fromString(message);
          if(messageObj is UserIdMessage) {
            userId = (messageObj as UserIdMessage).userId;
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
          } else if(messageObj is SentMessageMessage) {
            setState(() {
              this.userMessages.add(messageObj.userMessage);
            });
          } else if(messageObj is VideoIdAndMessageCatchupMessage) {
            this.userMessages.addAll(messageObj.userMessages);
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
          }
        },
        onError: (error, StackTrace stackTrace){
          debugPrint('onError');
        },
        onDone: (){
          debugPrint('Communication Closed');
        }
    );
  }

  void joinSession(String userIdForJoin, String nickNameForJoin, String sessionIdForJoin) {
    UserSettings userSettings = new UserSettings(true, "Sailor Cat.svg", userIdForJoin, nickNameForJoin);
    JoinSessionContent joinSessionContent = new JoinSessionContent(sessionIdForJoin, userIdForJoin, userSettings);
    sendMessage(new JoinSessionMessage(joinSessionContent));
    sessionJoined = true;
  }

  void sendGetServerTimeMessage() {
    GetServerTimeContent getServerTimeContent = new GetServerTimeContent("1.7.8");
    sendMessage(new GetServerTimeMessage(getServerTimeContent));
  }

  void sendMessage(SocketMessage message) {
    messenger.sendMessage(message);
  }

  void clearAllVariables() {
    setState(() {
      currentChannel = null;
      userId = null;
      sessionId = null;
      currentServerTime = 0;
      currentLocalTime = 0;
      lastKnownMoviePosition = 0;
      sessionJoined = false;
      userMessages.clear();
    });
  }

  @override
  void dispose() {
    debugPrint("Disposing...");
    currentChannel.sink.close();
    if(serverTimeTimer != null) {
      serverTimeTimer.cancel();
      serverTimeTimer = null;
    }
    if(pingTimer != null) {
      pingTimer.cancel();
      pingTimer = null;
    }
    clearAllVariables();
    super.dispose();
  }
  
  //WIDGET FUNCTIONS

  goToAccountSettings(BuildContext) async {
    print("go to account settings");
    await Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => UserSettingsScreen()),
    );
    _loadUsernameAndIcon();
  }

  List<Widget> getNotConnectedWidgets() {
    List<Widget> widgets = new List<Widget>();
    widgets.add(TextFormField(
      controller: _controller,
      decoration: InputDecoration(labelText: 'Enter URL'),
    ));
    widgets.add(FlatButton(
      color: Colors.blue,
      textColor: Colors.white,
      onPressed: () => connectToServer(),
      child: Text(
        "Connect",
      ),
    ));
    return widgets;
  }

  List<Widget> getConnectedWidgets() {
    List<Widget> widgets = new List<Widget>();
    widgets.add(getPlayOrPauseButtonWidget());
    widgets.add(getMessageSendBox());
    widgets.add(FlatButton(
      color: Colors.blue,
      textColor: Colors.white,
      onPressed: () => sendMessageToChat(),
      child: Text(
        "Send Message",
      ),
    ));
    String username;
    Iterator<UserMessage> itr = this.userMessages.iterator;
    while(itr.moveNext()) {
      UserMessage message = itr.current;
      username = "";
      if(message != null && message.userNickname != null) {
        username = message.userNickname;
      }
      widgets.add(Text(username + " - " + message.body));
    }
    return widgets;
  }

  void disconnectButtonPressed() {
    try {
      this.currentChannel.sink.close();
      this.serverTimeTimer.cancel();
      this.pingTimer.cancel();
    } on Exception {}
    setState(() {
      connected = false;
      clearAllVariables();
    });
  }

  Widget getPlayOrPauseButtonWidget() {
    if(!connected) {
      return Text("");
    } else {
      if (isPlaying) {
        return FlatButton(
          color: Colors.blue,
          textColor: Colors.white,
          onPressed: () {
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
          },
          child: Text(
            "Pause",
          ),
        );
      } else {
        return FlatButton(
          color: Colors.blue,
          textColor: Colors.white,
          onPressed: () {
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
          },
          child: Text(
            "Play",
          ),
        );
      }
    }
  }

  List<Widget> getActionIcons(BuildContext context) {
    List<Widget> widgets = new List<Widget>();
    if(this.connected) {
      widgets.add(IconButton(
        icon: Icon(Icons.cloud_off),
        onPressed: () {
          disconnectButtonPressed();
        },
      ));
    }
    widgets.add(IconButton(
      icon: Icon(Icons.account_circle),
      onPressed: () {
        goToAccountSettings(context);
      },
    ));
    return widgets;
  }

  Widget getMessageSendBox() {
    if(connected) {
      return Form(
          child: TextFormField(
            controller: _messageController,
            decoration: InputDecoration(labelText: 'Post a message'),
          ));
    } else {
      return Text("Can't send messages when not connected");
    }
  }
}


