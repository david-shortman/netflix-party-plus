import 'package:flutter/material.dart';

class PartyHarderTheme {
  static getLightTheme() {
    return new ThemeData(
        primaryColor: Colors.redAccent,
        unselectedWidgetColor: Colors.black,
        cardColor: Colors.black12
    );
  }
  static getDarkTheme() {
    return new ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.redAccent,
        accentColor: Colors.redAccent,
        buttonColor: Colors.redAccent,
        dialogBackgroundColor: Colors.blueGrey,
        cardColor: Colors.white12,
        unselectedWidgetColor: Colors.white60
    );
  }
}