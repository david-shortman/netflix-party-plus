import 'package:np_plus/domains/messages/SocketMessage.dart';
import 'package:np_plus/domains/messages/incoming-messages/ReceivedMessage.dart';
import 'package:web_socket_channel/io.dart';

class SocketMessengerService {
  IOWebSocketChannel _channel;
  int _sequenceNum = 0;

  SocketMessengerService();

  void establishConnection(
      String url,
      Function(ReceivedMessage) onReceivedMessage,
      Function onConnectionClosed,
      Function onConnectionOpened) {
    _channel = IOWebSocketChannel.connect(url);
    _channel.stream.listen(onReceivedMessage, onDone: onConnectionClosed);
    onConnectionOpened();
  }

  void closeConnection() {
    _channel.sink.close();
  }

  void sendRawMessage(String rawMessage) {
    _channel.sink.add(rawMessage);
    _sequenceNum++;
  }

  void sendMessage(SocketMessage message) {
    _channel.sink.add(message.buildString(_sequenceNum));
    _sequenceNum++;
  }
}
