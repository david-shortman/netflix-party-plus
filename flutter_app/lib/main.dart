import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:np_plus/services/SocketMessengerService.dart';

import 'package:np_plus/pages/AppContainer.dart';
import 'package:np_plus/services/LocalUserService.dart';
import 'package:np_plus/services/PartyService.dart';
import 'package:np_plus/services/ToastService.dart';
import 'package:np_plus/store/LocalUserStore.dart';
import 'package:np_plus/store/PartySessionStore.dart';
import 'package:np_plus/store/ChatMessagesStore.dart';
import 'package:np_plus/store/PlaybackInfoStore.dart';
import 'package:np_plus/services/SomeoneIsTypingService.dart';

GetIt getIt = GetIt.asNewInstance();

void main() {
  getIt.registerSingleton(PartySessionStore());
  final npServerInfoStore = getIt.get<PartySessionStore>();
  getIt.registerSingleton(PlaybackInfoStore());
  final playbackInfoStore = getIt.get<PlaybackInfoStore>();
  getIt.registerSingleton(ChatMessagesStore());
  final chatMessagesStore = getIt.get<ChatMessagesStore>();
  getIt.registerSingleton(SomeoneIsTypingService(chatMessagesStore));
  final someoneIsTypingService = getIt.get<SomeoneIsTypingService>();
  getIt.registerSingleton(LocalUserStore());
  getIt.registerSingleton(SocketMessengerService());
  final socketMessenger = getIt.get<SocketMessengerService>();
  getIt.registerSingleton(ToastService());
  final toastService = getIt.get<ToastService>();
  final localUserStore = getIt.get<LocalUserStore>();
  getIt.registerSingleton(LocalUserService(localUserStore));
  final localUserService = getIt.get<LocalUserService>();
  getIt.registerSingleton(PartyService(
      socketMessenger,
      toastService,
      playbackInfoStore,
      localUserService,
      chatMessagesStore,
      someoneIsTypingService,
      npServerInfoStore));
  WidgetsFlutterBinding.ensureInitialized();
  localUserService.initializeLocalUserFromSharedPreferences();

  runApp(MyApp());
}
