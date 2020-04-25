import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:np_plus/domains/messenger/SocketMessenger.dart';

import 'package:np_plus/pages/AppContainer.dart';
import 'package:np_plus/services/LocalUserService.dart';
import 'package:np_plus/store/LocalUserStore.dart';
import 'package:np_plus/store/NPServerInfoStore.dart';
import 'package:np_plus/store/ChatMessagesStore.dart';
import 'package:np_plus/store/PlaybackInfoStore.dart';
import 'package:np_plus/services/SomeoneIsTypingService.dart';

GetIt getIt = GetIt.asNewInstance();

void main() {
  getIt.registerSingleton(NPServerInfoStore());
  getIt.registerSingleton(PlaybackInfoStore());
  getIt.registerSingleton(ChatMessagesStore());
  final chatMessagesStore = getIt.get<ChatMessagesStore>();
  getIt.registerSingleton(SomeoneIsTypingService(chatMessagesStore));
  getIt.registerSingleton(LocalUserStore());
  getIt.registerSingleton(SocketMessenger());
  final localUserStore = getIt.get<LocalUserStore>();
  getIt.registerSingleton(LocalUserService(localUserStore));
  final localUserService = getIt.get<LocalUserService>();
  WidgetsFlutterBinding.ensureInitialized();
  localUserService.initializeLocalUserFromSharedPreferences();

  runApp(MyApp());
}
