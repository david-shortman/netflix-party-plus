import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:np_plus/domains/server/ServerInfo.dart';
import 'package:np_plus/main.dart';
import 'package:np_plus/services/PartyService.dart';
import 'package:np_plus/services/ToastService.dart';
import 'package:np_plus/store/PartySessionStore.dart';
import 'package:progress_button/progress_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LandingPage extends StatefulWidget {
  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  bool _isAttemptingToJoinSessionFromText = false;
  bool _isAttemptingToJoinSessionFromQR = false;
  TextEditingController _urlTextController = TextEditingController();

  final _npServerInfoStore = getIt.get<PartySessionStore>();
  final _toastService = getIt.get<ToastService>();
  final _partyService = getIt.get<PartyService>();

  _LandingPageState();

  @override
  Widget build(BuildContext ctxt) {
    return SingleChildScrollView(
        child: Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: _getLandingPageWidgets(),
            )));
  }

  List<Widget> _getLandingPageWidgets() {
    List<Widget> widgets = List<Widget>();
    widgets.add(Padding(
      padding: EdgeInsets.all(6),
    ));
    widgets.add(
      Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Party URL",
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: 20),
          )),
    );
    widgets.add(Padding(
      padding: EdgeInsets.all(4),
    ));
    widgets.add(CupertinoTextField(
      textInputAction: TextInputAction.go,
      onSubmitted: (text) {
        _onConnectIntent();
      },
      controller: _urlTextController,
      placeholder: 'Enter URL',
      style: Theme.of(context).primaryTextTheme.body1,
      clearButtonMode: OverlayVisibilityMode.editing,
    ));
    widgets.add(Padding(
      padding: EdgeInsets.fromLTRB(50, 10, 50, 10),
      child: ProgressButton(
        child: Text(
          _isAttemptingToJoinSessionFromText ? "" : "Connect to Party",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: _onConnectIntent,
        buttonState: _isAttemptingToJoinSessionFromText
            ? ButtonState.inProgress
            : ButtonState.normal,
        backgroundColor: Theme.of(context).primaryColor,
        progressColor: Colors.white,
      ),
    ));
    widgets.add(Padding(
        padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
        child: Text(
          "OR",
          style: TextStyle(fontWeight: FontWeight.bold),
        )));
    widgets.add(Padding(
        padding: EdgeInsets.fromLTRB(0, 4, 0, 4),
        child: Align(
            alignment: Alignment.centerLeft,
            child:
                Text("1. Copy the link from Netflix Party on your computer"))));
    widgets.add(Padding(
        padding: EdgeInsets.fromLTRB(0, 4, 0, 4),
        child: Align(
            alignment: Alignment.centerLeft,
            child: Text("2. Visit the-qrcode-generator.com"))));
    widgets.add(Padding(
        padding: EdgeInsets.fromLTRB(0, 4, 0, 4),
        child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
                "3. Paste the link there to create a scannable QR code"))));
    widgets.add(Padding(
      padding: EdgeInsets.fromLTRB(50, 10, 50, 10),
      child: ProgressButton(
        child: Text(
          _isAttemptingToJoinSessionFromQR ? "" : "Scan QR Code",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: _onScanQRPressed,
        buttonState: _isAttemptingToJoinSessionFromQR
            ? ButtonState.inProgress
            : ButtonState.normal,
        backgroundColor: Theme.of(context).primaryColor,
        progressColor: Colors.white,
      ),
    ));
    return widgets;
  }

  void _onScanQRPressed() async {
    var result = await BarcodeScanner.scan();
    _urlTextController.text = result;
    _connectToServer();
    setState(() {
      _isAttemptingToJoinSessionFromQR = true;
    });
  }

  void _onConnectIntent() {
    setState(() {
      _isAttemptingToJoinSessionFromText = true;
    });
    _connectToServer();
  }

  void _connectToServer() {
    _updateLastJoinedPartyUrl();
    _npServerInfoStore
        .updatePartySession(PartySession.fromUrl(url: _urlTextController.text));
    if (_npServerInfoStore.partySession.isMetadataIncomplete()) {
      _onConnectFailed();
    }
    _partyService.joinParty(_npServerInfoStore.partySession);
  }

  void _updateLastJoinedPartyUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("lastPartyUrl", _urlTextController.text);
  }

  void _onConnectFailed() {
    _toastService.showToastMessage("Invalid Link");
    setState(() {
      _isAttemptingToJoinSessionFromText = false;
      _isAttemptingToJoinSessionFromQR = false;
    });
  }
}
