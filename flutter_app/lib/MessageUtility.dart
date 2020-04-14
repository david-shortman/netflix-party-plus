import 'dart:convert';

import 'package:flutterapp/Message.dart';
import 'package:flutterapp/MessageArray.dart';
import 'package:flutterapp/MessageObject.dart';
import 'package:flutterapp/MessageSendMessage.dart';
import 'package:flutterapp/MessageServerTime.dart';
import 'package:flutterapp/MessageSid.dart';
import 'package:flutterapp/MessageUpdate.dart';
import 'package:flutterapp/MessageUserId.dart';

import 'MessageVideoIdAndMessageBacklog.dart';

class MessageUtility {
  Message interpretMessage(String message) {
    int firstSquareBracket = message.toString().indexOf("[");
    int firstCurlyBracket = message.toString().indexOf("{");
    int seqNo = 0;
    if(firstSquareBracket < 0) {
      firstSquareBracket = 9999999;
    }
    if(firstCurlyBracket < 0) {
      firstCurlyBracket = 9999999;
    }
    if(firstCurlyBracket < firstSquareBracket) {
      Map<String, dynamic> messageObj = jsonDecode(message.toString().substring(message.indexOf("{")));
      if(messageObj.containsKey("sid")) {
        return new SidMessage(messageObj);
      }
      return new ObjectMessage(message);
      print("this is an object "+ message);
    } else if (firstSquareBracket < firstCurlyBracket) {
      //seqNo = int.parse(message.toString().substring(0, firstSquareBracket));
      var arrayJson = jsonDecode(message.toString().substring(firstSquareBracket));
      List<Object> arrayItems = arrayJson != null ? List.from(arrayJson) : null;
      if(arrayItems.length == 0) {
        return new Message();
      }
      if(arrayItems.elementAt(0) == "userId") {
        return new UserIdMessage(arrayItems.elementAt(1));
      } else if(arrayItems.elementAt(0) == "sendMessage") {
        return new MessageSendMessage(arrayItems.elementAt(1));
      } else if (arrayItems.elementAt(0) == "update") {
        return new UpdateMessage(arrayItems.elementAt(1));
      } else if(arrayItems.length == 1) {
        if(arrayItems.elementAt(0) is int) {
          return new ServerTimeMessage(arrayItems.elementAt(0));
        } else if((arrayItems.elementAt(0) as Map<String, dynamic>).containsKey("videoId")) {
          return new VideoIdAndMessageCatchupMessage(
              (arrayItems.elementAt(0) as Map<String, dynamic>));
        }
      } else {
        return new ArrayMessage(message);
      }

      }
      return new Message();
    }
}