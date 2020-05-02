import 'package:flutter/material.dart';

class PartyHarderTheme {
  static getLightTheme() {
    return ThemeData(
        primaryColor: Colors.red,
        unselectedWidgetColor: Colors.black,
        cardColor: Colors.black12,
        bottomAppBarColor: Colors.white,
        dialogBackgroundColor: Colors.white,
        selectedRowColor: Colors.grey[200],
        primaryTextTheme: TextTheme(
            body1: TextStyle(color: Colors.black),
            headline: TextStyle(color: Colors.black12)));
  }

  static getDarkTheme() {
    return ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.red,
        accentColor: Colors.red,
        bottomAppBarColor: Color.fromRGBO(20, 20, 20, 1),
        backgroundColor: Colors.black,
        scaffoldBackgroundColor: Colors.black,
        canvasColor: Colors.black,
        dialogBackgroundColor: Colors.black87,
//        dialogBackgroundColor: Colors.black38,
        primaryTextTheme: TextTheme(
            body1: TextStyle(color: Colors.white),
            headline: TextStyle(color: Colors.white70)));
  }
}
