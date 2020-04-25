//import 'dart:async';
//
//import 'package:flutter/cupertino.dart';
//import 'package:np_plus/domains/messenger/SocketMessenger.dart';
//import 'package:np_plus/domains/server/ServerInfo.dart';
//import 'package:np_plus/playback/PlaybackInfo.dart';
//import 'package:web_socket_channel/io.dart';
//
//class PartySession {
//  bool _hasJoinedSession = false;
//  bool _isConnected = false;
//  String _userId;
//  NPServerInfo _npServerInfo;
//  PlaybackInfo _playbackInfo;
//  String _videoId;
//  SocketMessenger _npMessenger;
//  Function _onFailToConnect = () {};
//  Function _onSessionStateChanged = () {};
//
//  PartySession({ NPServerInfo npServerInfo, localTimeAtLastUpdate, int lastKnownMoviePosition, bool isPlaying, Function onFailToConnect, Function onSessionStateChanged }) {
//    _npServerInfo = npServerInfo;
//    _playbackInfo = PlaybackInfo(localTimeAtLastUpdate: localTimeAtLastUpdate, lastKnownMoviePosition: lastKnownMoviePosition, isPlaying: isPlaying);
//    _onFailToConnect = onFailToConnect;
//    _onSessionStateChanged = onSessionStateChanged;
//  }
//
//  bool isVideoPlaying() {
//    return _playbackInfo.isPlaying;
//  }
//
//  void connectToServer(String url) {
//    _npServerInfo = _parseServerInfoFromUrl(url);
//    if (_npServerInfo.isIncomplete()) {
//      _onFailToConnect();
//    }
//    _connectAndSetupListener(_npServerInfo.serverId);
//  }
//
//  void _connectAndSetupListener(String serverId) {
//    _isConnected = true;
//    _npMessenger.establishConnection("wss://$serverId.netflixparty.com/socket.io/?EIO=3&transport=websocket");
//    currentChannel.stream.listen(_onReceivedStreamMessage,
//        onError: (error, StackTrace stackTrace) {
//          debugPrint('stream error: ${stackTrace.toString()}');
//        }, onDone: () {
//          _isConnected = false;
//          _onSessionStateChanged();
//        });
//  }
//
//  NPServerInfo _parseServerInfoFromUrl(String url) {
//    Uri uri = Uri.parse(url);
//    return NPServerInfo(
//        sessionId: uri.queryParameters['npSessionId'],
//        serverId: uri.queryParameters['npServerId']);
//  }
//}