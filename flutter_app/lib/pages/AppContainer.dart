import 'dart:async';
import 'package:dash_chat/dash_chat.dart';
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
import 'package:rxdart/rxdart.dart';
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
  final BehaviorSubject<bool> _isKeyboardVisible =
      BehaviorSubject.seeded(false);

  int _sessionLastActiveAtTime = 0;

  bool _isShowingChangelogDialog = false;

  int _numChatUsers = 0;

  UniqueKey chatUniqueKey = UniqueKey();

  _AppContainerState() {
    _setupLocalUserListener();
    _setupSessionUpdatedListener();
    _setupUsersListener();
    _dispatchShowChangelogIntent();
    WidgetsBinding.instance.addObserver(this);
    KeyboardVisibilityNotification()
        .addNewListener(onChange: _isKeyboardVisible.add);
  }

  void _setupLocalUserListener() {
    _localUserStore.stream$.listen(_onLocalUserChanged);
  }

  void _setupUsersListener() {
    _chatMessagesStore.chatUserStream$.listen(_onChatUsersChanged);
  }

  void _onChatUsersChanged(List<ChatUser> chatUsers) {
    setState(() {
      _numChatUsers = chatUsers.length;
    });
  }

  void _setupSessionUpdatedListener() {
    _partySessionStore.stream$.listen(_onSessionUpdated);
  }

  void _onLocalUserChanged(LocalUser localUser) {
    if (_partySessionStore.isSessionActive) {
      _sendBroadcastUserSettingsMessage(localUser);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_partySessionStore.isSessionActive &&
          itHasBeenLessThan30MinutesSinceDisconnectedFromTheLastSession()) {
        _partyService.rejoinLastParty();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CupertinoNavigationBar(
        brightness: MediaQuery.of(context).platformBrightness,
        middle: StreamBuilder(
            stream: _partySessionStore.isSessionActive$,
            builder: (context, isSessionActiveSnapshot) {
              bool isSessionActive = isSessionActiveSnapshot.data ?? false;
              return RichText(
                text: TextSpan(
                    style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).textTheme.bodyText1.color),
                    children: isSessionActive
                        ? [
                            TextSpan(
                                text:
                                    "$_numChatUsers ${_numChatUsers > 1 ? 'people' : 'person'}")
                          ]
                        : [
                            TextSpan(
                              text: LabelVault.LANDING_PAGE_TITLE,
                            ),
                          ]),
              );
            }),
        backgroundColor: CupertinoColors.quaternarySystemFill,
      ),
      body: StreamBuilder(
        stream: _partySessionStore.isSessionActive$,
        builder: (context, AsyncSnapshot<bool> isSessionActiveSnapshot) {
          bool isSessionActive = isSessionActiveSnapshot.data ?? false;
          return Stack(
            children: <Widget>[
              isSessionActive ? _getPartyPage() : LandingPage(),
              StreamBuilder(
                stream: _isKeyboardVisible.stream,
                builder:
                    (context, AsyncSnapshot<bool> isKeyboardVisibleSnapshot) {
                  return Visibility(
                      visible: !(isKeyboardVisibleSnapshot.data ?? false),
                      child: ControlPanel());
                },
              )
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: StreamBuilder(
        stream: _chatMessagesStore.isSomeoneTypingStream$,
        builder: (context, AsyncSnapshot<bool> chatMessagesSnapshot) {
          return Visibility(
            visible: chatMessagesSnapshot.data ?? false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(0, 0, 0, 190),
              child: Container(
                width: 200,
                height: 35,
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    "People are typing...",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                decoration: BoxDecoration(
                    color: Color.fromRGBO(0, 0, 0, .5),
                    borderRadius: BorderRadius.all(Radius.circular(12.0))),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _getPartyPage() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: StreamBuilder(
          stream: _isKeyboardVisible.stream,
          builder: (context, AsyncSnapshot<bool> isKeyboardVisibleSnapshot) {
            double bottomPadding = isKeyboardVisibleSnapshot.data != null &&
                    isKeyboardVisibleSnapshot.data
                ? MediaQuery.of(context).viewInsets.bottom + 5
                : 120;
            return SizedBox(
                height: MediaQuery.of(context).size.height - 64,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(6, 0, 6, bottomPadding),
                  child: ChatFeedPage(
                    key: chatUniqueKey,
                  ),
                ));
          }),
    );
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
    if (!_partySessionStore.isSessionActive) {
      _playbackInfoStore.updateServerTimeAtLastUpdate(0);
      _playbackInfoStore.updateLastKnownMoviePosition(0);
      _chatMessagesStore.clearMessages();
      _sessionLastActiveAtTime = 0;
    } else {
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
