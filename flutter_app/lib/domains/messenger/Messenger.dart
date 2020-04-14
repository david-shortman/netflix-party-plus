import 'package:flutter/foundation.dart';
import 'package:flutterapp/domains/messages/Message.dart';
import 'package:web_socket_channel/io.dart';

class Messenger {
  IOWebSocketChannel _channel;

  Messenger() {}

  void setChannel(IOWebSocketChannel channel) {
    _channel = channel;
  }

  void sendMessage(SocketMessage message, int currentSequenceNum) {
    debugPrint("Sending message: | ${message.buildString(currentSequenceNum)}");
    _channel.sink.add(message.buildString(currentSequenceNum));
  }
}
