import 'package:flutterapp/domains/messages/SocketMessage.dart';
import 'package:web_socket_channel/io.dart';

class Messenger {
  IOWebSocketChannel _channel;
  int _currentSequenceNum = 0;

  Messenger();
  void setChannel(IOWebSocketChannel channel) {
    _channel = channel;
  }

  void sendMessage(SocketMessage message) {
    _channel.sink.add(message.buildString(_currentSequenceNum));
    _currentSequenceNum++;
  }
}
