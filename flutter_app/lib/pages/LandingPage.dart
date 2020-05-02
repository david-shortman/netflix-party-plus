import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:np_plus/GetItInstance.dart';
import 'package:np_plus/domains/server/ServerInfo.dart';
import 'package:np_plus/services/PartyService.dart';
import 'package:np_plus/services/ToastService.dart';
import 'package:np_plus/store/PartySessionStore.dart';
import 'package:np_plus/vaults/LabelVault.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LandingPage extends StatefulWidget {
  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  TextEditingController _urlTextController = TextEditingController();
  final BehaviorSubject<bool> _isAttemptingToJoinSessionFromText$ =
      BehaviorSubject.seeded(false);

  final _npServerInfoStore = getIt.get<PartySessionStore>();
  final _toastService = getIt.get<ToastService>();
  final _partyService = getIt.get<PartyService>();

  _LandingPageState();

  @override
  void initState() {
    super.initState();

    _loadLastPartyUrl();
  }

  void _loadLastPartyUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _urlTextController.text = prefs.getString("lastPartyUrl") ?? "";
  }

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
    widgets.add(Padding(
        padding: EdgeInsets.fromLTRB(0, 4, 0, 4),
        child: Align(
            alignment: Alignment.centerLeft,
            child: Text("1. Copy the Netflix Party link onto your phone"))));
    widgets.add(Padding(
      padding: EdgeInsets.all(5),
    ));
    widgets.add(StreamBuilder(
        stream: _isAttemptingToJoinSessionFromText$.stream,
        builder: (context,
            AsyncSnapshot<bool> isAttemptingToJoinSessionFromTextSnapshot) {
          bool isAttemptingToJoinSessionFromText =
              isAttemptingToJoinSessionFromTextSnapshot.data != null
                  ? isAttemptingToJoinSessionFromTextSnapshot.data
                  : false;
          return Padding(
            padding: EdgeInsets.fromLTRB(50, 10, 50, 10),
            child: CupertinoButton(
              color: Theme.of(context).primaryColor,
              child: Align(
                alignment: Alignment.center,
                child: isAttemptingToJoinSessionFromText ? CupertinoTheme(data: CupertinoThemeData(brightness: Brightness.dark), child: CupertinoActivityIndicator(),) : Text('${LabelVault.CONNECT_TO_PARTY_BUTTON.toString()}',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              onPressed: _onConnectIntent,
            ),
          );
        }));
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
            child: Text("1. Visit the-qrcode-generator.com"))));
    widgets.add(Padding(
        padding: EdgeInsets.fromLTRB(0, 4, 0, 4),
        child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
                "2. Paste the link there to create a scannable QR code"))));
    widgets.add(Padding(
      padding: EdgeInsets.fromLTRB(50, 10, 50, 10),
      child: CupertinoButton(
        color: Theme.of(context).primaryColor,
        child: Text(
          LabelVault.SCAN_QR_BUTTON,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: _onScanQRPressed,
      ),
    ));
    return widgets;
  }

  void _onScanQRPressed() async {
    await HapticFeedback.lightImpact();
    String result = await BarcodeScanner.scan();
    _urlTextController.text = result;
    _connectToServer();
  }

  void _onConnectIntent() async {
    await HapticFeedback.lightImpact();
    _urlTextController.text = (await Clipboard.getData('text/plain')).text;
    setState(() {
      _isAttemptingToJoinSessionFromText$.add(true);
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
    _isAttemptingToJoinSessionFromText$.add(false);
  }
}
