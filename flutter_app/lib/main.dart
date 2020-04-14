import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutterapp/MessageArray.dart';
import 'package:flutterapp/MessageObject.dart';
import 'package:flutterapp/MessageSendMessage.dart';
import 'package:flutterapp/MessageServerTime.dart';
import 'package:flutterapp/MessageSid.dart';
import 'package:flutterapp/MessageUpdate.dart';
import 'package:flutterapp/MessageUserId.dart';
import 'package:flutterapp/MessageUtility.dart';
import 'package:flutterapp/MessageVideoIdAndMessageBacklog.dart';
import 'package:flutterapp/UserMessage.dart';
import 'package:flutterapp/domains/messages/Message.dart';
import 'package:flutterapp/domains/messages/buffering/BufferingContent.dart';
import 'package:flutterapp/domains/messages/buffering/BufferingMessage.dart';
import 'package:flutterapp/domains/messages/chat-message/SendMessageBody.dart';
import 'package:flutterapp/domains/messages/chat-message/SendMessageContent.dart';
import 'package:flutterapp/domains/messages/chat-message/SendMessageMessage.dart';
import 'package:flutterapp/domains/messages/join-session/JoinSessionContent.dart';
import 'package:flutterapp/domains/messages/join-session/JoinSessionMessage.dart';
import 'package:flutterapp/domains/messages/join-session/UserSettings.dart';
import 'package:flutterapp/domains/messages/server-time/GetServerTimeMessage.dart';
import 'package:flutterapp/domains/messages/server-time/GetServerTimeContent.dart';
import 'package:flutterapp/domains/messages/update-session/UpdateSessionContent.dart';
import 'package:flutterapp/domains/messages/update-session/UpdateSessionMessage.dart';
import 'package:flutterapp/domains/messenger/Messenger.dart';
import 'package:web_socket_channel/io.dart';

import 'ReceivedMessage.dart';

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
  int currentSequenceNum = 0;
  int currentServerTime = 0;
  int currentLocalTime = 0;
  int lastKnownMoviePosition = 0;
  bool sessionJoined = false;
  MessageUtility messageUtility = new MessageUtility();
  SidMessage sidMessage;
  TextEditingController _controller = TextEditingController();
  TextEditingController _messageController = TextEditingController();
  Timer serverTimeTimer;
  Timer pingTimer;
  bool isPlaying = false;
  bool connected = false;
  int videoDuration = 655550;
  List<UserMessage> userMessages = new List();




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
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
    SendMessageContent sendMessageContent = new SendMessageContent(new SendMessageBody(messageText, false, expectedServerTime, userId, userId, "Sailor Cat.svg", "Mobile User"));
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
      print("ServerId: "+serverId);
      print("SessionId: "+sessionId);
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
              print(message);
          ReceivedMessage messageObj = messageUtility.interpretMessage(message);
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
            print("last Known time - "+ messageObj.lastKnownTime.toString()+" at "+messageObj.lastKnownTimeUpdatedAt.toString());
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
          } else if(messageObj is SidMessage) {
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
          } else if(messageObj is MessageSendMessage) {
            setState(() {
              this.userMessages.add(messageObj.userMessage);
            });
          } else if(messageObj is VideoIdAndMessageCatchupMessage) {
            this.userMessages.addAll(messageObj.userMessages);
            lastKnownMoviePosition = messageObj.lastKnownTime;
            currentServerTime = messageObj.lastKnownTimeUpdatedAt;
            currentLocalTime = (new DateTime.now().millisecondsSinceEpoch);
            print("last Known time - "+ messageObj.lastKnownTime.toString()+" at "+messageObj.lastKnownTimeUpdatedAt.toString());
            sendNotBufferingMessage();
            print(messageObj.state);
            setState(() {
              if(messageObj.state == "playing") {
                this.isPlaying = true;
              } else {
                this.isPlaying = false;
              }
            });
          } else if(messageObj is ObjectMessage) {
            print("Unknown Object Message!");
          } else if(messageObj is ArrayMessage) {
            print("Unknown Array Message!");
          } else {
            print(messageObj);
            print("Completely Unknown Message!");
          }
        },
        onError: (error, StackTrace stackTrace){
          // error handling
          print('onError');
        },
        onDone: (){
          // communication has been closed
          print('Communication Closed');
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
    messenger.sendMessage(message, currentSequenceNum);
    currentSequenceNum++;
  }

  void clearAllVariables() {
    setState(() {
      currentChannel = null;
      messenger = null;
      userId = null;
      sessionId = null;
      currentSequenceNum = 0;
      currentServerTime = 0;
      currentLocalTime = 0;
      lastKnownMoviePosition = 0;
      sessionJoined = false;
      userMessages.clear();
      MessageUtility messageUtility = new MessageUtility();
      SidMessage sidMessage;
      TextEditingController _controller = TextEditingController();
      TextEditingController _messageController = TextEditingController();
      Timer timer;
      bool isPlaying = false;
      bool connected = false;
      int videoDuration = 655550;
    });
  }

  @override
  void dispose() {
    print("Disposing...");
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
    widgets.add(getDisconnectButtonWidget());
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

  Widget getDisconnectButtonWidget() {
    return FlatButton(
      color: Colors.blue,
      textColor: Colors.white,
      onPressed: () {
        print("button pressed");

        try {
          this.currentChannel.sink.close();
          this.serverTimeTimer.cancel();
          this.pingTimer.cancel();
        } on Exception {}
        setState(() {
          connected = false;
          clearAllVariables();
        });
      },
      child: Text(
        "Click To Disconnect",
      ),
    );
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

            print('sending pause with movie time: ' + expectedMovieTime.toString());
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
            print('sending play with movie time: ' + lastKnownMoviePosition.toString());
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


