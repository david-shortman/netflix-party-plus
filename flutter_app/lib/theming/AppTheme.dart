import 'package:flutter/material.dart';

class PartyHarderTheme {
  static getLightTheme() {
    return ThemeData(
        primaryColor: Colors.red,
        unselectedWidgetColor: Colors.black,
        cardColor: Colors.black12,
        bottomAppBarColor: Colors.white70,
        primaryTextTheme: TextTheme(body1: TextStyle(color: Colors.black)));
  }

  static getDarkTheme() {
    return ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.red,
        accentColor: Colors.red,
        bottomAppBarColor: Colors.black87,
        primaryTextTheme: TextTheme(body1: TextStyle(color: Colors.white)));
  }
}
