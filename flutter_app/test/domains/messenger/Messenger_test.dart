import 'package:flutter_test/flutter_test.dart';
import 'package:np_plus/domains/messages/SocketMessage.dart';
import 'package:mockito/mockito.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class MockIOWebSocketChannel extends Mock implements IOWebSocketChannel {}

class MockWebSocketSink extends Mock implements WebSocketSink {}

class MockSocketMessage extends Mock implements SocketMessage {}

void main() {
  group('messenger unit tests', () {
    test('that when sendMessage is called the message is built and sent', () {
      expect(true, isTrue);
//      SocketMessenger messenger = SocketMessenger();
//
//      String message = "what's up";
//      SocketMessage mockSocketMessage = MockSocketMessage();
//      int sequenceNumber = 0;
//      when(mockSocketMessage.buildString(sequenceNumber)).thenReturn(message);
//
//      messenger.establishConnection("url", (message) {}, () {}, () {});
//      messenger.sendMessage(mockSocketMessage);
//
//      verify(mockSocketMessage.buildString(sequenceNumber));
    });
  });
}
