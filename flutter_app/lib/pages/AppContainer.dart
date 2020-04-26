import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:np_plus/GetItInstance.dart';
import 'package:np_plus/changelog/ChangelogService.dart';
import 'package:np_plus/domains/server/ServerInfo.dart';
import 'package:np_plus/domains/user/LocalUser.dart';
import 'package:np_plus/pages/LandingPage.dart';
import 'package:np_plus/services/PartyService.dart';
import 'package:np_plus/store/LocalUserStore.dart';
import 'package:np_plus/store/PartySessionStore.dart';
import 'package:np_plus/store/ChatMessagesStore.dart';
import 'package:np_plus/store/PlaybackInfoStore.dart';
import 'package:np_plus/theming/AppTheme.dart';
import 'package:np_plus/vaults/LabelVault.dart';
import 'package:np_plus/vaults/PreferencePropertyVault.dart';
import 'package:np_plus/widgets/ChangelogDialog.dart';
import 'package:np_plus/pages/ChatFeedPage.dart';
import 'package:keyboard_visibility/keyboard_visibility.dart';
import 'package:np_plus/widgets/ControlPanel.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domains/avatar/Avatar.dart';
import '../domains/messages/outgoing-messages/broadcast-user-settings/BroadCastUserSettingsMessage.dart';
import '../domains/messages/outgoing-messages/broadcast-user-settings/BroadcastUserSettingsContent.dart';
import '../domains/messages/outgoing-messages/join-session/UserSettings.dart';
import '../services/SocketMessengerService.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: '${LabelVault.APP_TITLE_1}${LabelVault.APP_TITLE_2}',
        theme: PartyHarderTheme.getLightTheme(),
        darkTheme: PartyHarderTheme.getDarkTheme(),
        home: AppContainer());
  }
}

class AppContainer extends StatefulWidget {
  AppContainer({Key key}) : super(key: key);

  @override
  _AppContainerState createState() => _AppContainerState();
}

class _AppContainerState extends State<AppContainer>
    with WidgetsBindingObserver {
  final _messenger = getIt.get<SocketMessengerService>();
  final _partySessionStore = getIt.get<PartySessionStore>();
  final _playbackInfoStore = getIt.get<PlaybackInfoStore>();
  final _chatMessagesStore = getIt.get<ChatMessagesStore>();
  final _localUserStore = getIt.get<LocalUserStore>();
  final _partyService = getIt.get<PartyService>();

  int _sessionLastActiveAtTime = 0;

  bool _isShowingChangelogDialog = false;

  bool _isKeyboardVisible = false;
  UniqueKey chatUniqueKey = UniqueKey();

  _AppContainerState() {
    _setupLocalUserListener();
    _setupSessionUpdatedListener();
    _dispatchShowChangelogIntent();
  }

  void _setupLocalUserListener() {
    _localUserStore.stream$.listen(_onLocalUserChanged);
  }

  void _setupSessionUpdatedListener() {
    _partySessionStore.stream$.listen(_onSessionUpdated);
  }

  void _onLocalUserChanged(LocalUser localUser) {
    if (_partySessionStore.isSessionActive()) {
      _sendBroadcastUserSettingsMessage(localUser);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_partySessionStore.isSessionActive() &&
          itHasBeenLessThan30MinutesSinceDisconnectedFromTheLastSession()) {
        _partyService.rejoinLastParty();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addObserver(this);
    KeyboardVisibilityNotification().addNewListener(onChange: (isVisible) {
      setState(() {
        _isKeyboardVisible = isVisible;
      });
    });
    return Scaffold(
        appBar: AppBar(
          title: RichText(
            text: TextSpan(
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24),
                children: [
                  TextSpan(
                    text: LabelVault.APP_TITLE_1,
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                  TextSpan(
                    text: LabelVault.APP_TITLE_2,
                  )
                ]),
          ),
          backgroundColor: Theme.of(context).primaryColor,
        ),
        body: StreamBuilder(
          stream: _partySessionStore.stream$,
          builder: (context, AsyncSnapshot<PartySession> partySessionSnapshot) {
            bool isSessionActive = partySessionSnapshot.data != null &&
                partySessionSnapshot.data.isSessionActive();
            return Stack(
              children: <Widget>[
                isSessionActive ? _getPartyPage() : LandingPage(),
                Visibility(visible: !_isKeyboardVisible, child: ControlPanel())
              ],
            );
          },
        ));
  }

  Widget _getPartyPage() {
    return SizedBox(
        height: MediaQuery.of(context).size.height - 210,
        child: Padding(
          padding: EdgeInsets.fromLTRB(6, 0, 6, 0),
          child: ChatFeedPage(
            key: chatUniqueKey,
          ),
        ));
  }

  Future<void> _showChangelogDialog() async {
    await showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return ChangelogDialog();
        });
  }

  void _dispatchShowChangelogIntent() {
    Future.delayed(Duration(milliseconds: 300), () async {
      if (!_isShowingChangelogDialog) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String lastViewedChangelog = await prefs
            .getString(PreferencePropertyVault.LAST_VIEWED_CHANGELOG_VERSION);
        if (lastViewedChangelog != ChangelogService.getLatestVersion()) {
          _isShowingChangelogDialog = true;
          await _showChangelogDialog();
          _isShowingChangelogDialog = false;
        }
      }
    });
  }

  void _sendBroadcastUserSettingsMessage(LocalUser user) {
    _messenger.sendMessage(BroadcastUserSettingsMessage(
        BroadCastUserSettingsContent(UserSettings(
            true, UserAvatar.getNPName(user.icon), user.id, user.username))));
  }

  void _onSessionUpdated(PartySession partySession) {
    if (!partySession.isSessionActive()) {
      _playbackInfoStore.updateServerTimeAtLastUpdate(0);
      _playbackInfoStore.updateLastKnownMoviePosition(0);
      _chatMessagesStore.clearMessages();
      _sessionLastActiveAtTime = 0;
    }
    if (partySession.isSessionActive()) {
      _sessionLastActiveAtTime = DateTime.now().millisecondsSinceEpoch;
    }
  }

  bool itHasBeenLessThan30MinutesSinceDisconnectedFromTheLastSession() {
    return DateTime.now().millisecondsSinceEpoch - _sessionLastActiveAtTime <
        1800;
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }
}
