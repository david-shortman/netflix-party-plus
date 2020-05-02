import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PartyHarderTheme {
  static getTheme() {
    return CupertinoThemeData(
        primaryColor: Colors.red,
        textTheme: CupertinoTextThemeData(textStyle: TextStyle(color: CupertinoDynamicColor.withBrightness(color: CupertinoColors.black, darkColor: CupertinoColors.white))),
        barBackgroundColor: CupertinoDynamicColor.withBrightness(color: CupertinoColors.systemBackground, darkColor: CupertinoColors.darkBackgroundGray),
//        unselectedWidgetColor: CupertinoColors.black,
//        cardColor: CupertinoColors.black12,
//        bottomAppBarColor: CupertinoColors.white,
//        dialogBackgroundColor: CupertinoColors.white,
//        selectedRowColor: CupertinoColors.grey[200],
//        primaryTextTheme: TextTheme(
//            body1: TextStyle(color: CupertinoColors.black),
//            headline: TextStyle(color: CupertinoColors.black12)));
    );
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
