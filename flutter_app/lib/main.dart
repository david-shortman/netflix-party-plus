import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';

import 'package:np_plus/pages/MainPage.dart';
import 'package:np_plus/store/NPServerInfoStore.dart';
import 'package:np_plus/store/PlaybackInfoStore.dart';

GetIt getIt = GetIt.asNewInstance();

void main() {
  getIt.registerSingleton(NPServerInfoStore());
  getIt.registerSingleton(PlaybackInfoStore());
  runApp(MyApp());
}
