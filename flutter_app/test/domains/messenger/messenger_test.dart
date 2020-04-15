import 'package:flutter_test/flutter_test.dart';
import 'package:flutterapp/domains/messages/Message.dart';
import 'package:flutterapp/domains/messenger/Messenger.dart';
import 'package:mockito/mockito.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class MockIOWebSocketChannel extends Mock implements IOWebSocketChannel {}
class MockWebSocketSink extends Mock implements WebSocketSink {}
class MockSocketMessage extends Mock implements SocketMessage {}

void main() {
  group('messenger unit tests', () {
    test('that when sendMessage is called the message is built and sent', () {
      Messenger messenger = new Messenger();
      IOWebSocketChannel mockIOWebSocketChannel = new MockIOWebSocketChannel();
      MockWebSocketSink mockWebSocketSink = new MockWebSocketSink();
      when(mockIOWebSocketChannel.sink).thenReturn(mockWebSocketSink);

      String message = "what's up";
      SocketMessage mockSocketMessage = new MockSocketMessage();
      int sequenceNumber = 0;
      when(mockSocketMessage.buildString(sequenceNumber)).thenReturn(message);

      messenger.setChannel(mockIOWebSocketChannel);
      messenger.sendMessage(mockSocketMessage);

      verify(mockSocketMessage.buildString(sequenceNumber));
      verify(mockWebSocketSink.add(message));
    });
  });
}
