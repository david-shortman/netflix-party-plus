import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:np_plus/changelog/ChangelogService.dart';
import 'package:np_plus/domains/media-controls/VideoState.dart';
import 'package:np_plus/domains/server/ServerInfo.dart';
import 'package:np_plus/domains/user/LocalUser.dart';
import 'package:np_plus/main.dart';
import 'package:np_plus/pages/LandingPage.dart';
import 'package:np_plus/services/PartyService.dart';
import 'package:np_plus/store/LocalUserStore.dart';
import 'package:np_plus/store/PartySessionStore.dart';
import 'package:np_plus/store/ChatMessagesStore.dart';
import 'package:np_plus/store/PlaybackInfoStore.dart';
import 'package:np_plus/theming/AppTheme.dart';
import 'package:np_plus/widgets/ChangelogDialogFactory.dart';
import 'package:np_plus/widgets/ChatFeed.dart';
import 'package:keyboard_visibility/keyboard_visibility.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../domains/avatar/Avatar.dart';
import 'UserSettingsPage.dart';
import '../domains/messages/outgoing-messages/broadcast-user-settings/BroadCastUserSettingsMessage.dart';
import '../domains/messages/outgoing-messages/broadcast-user-settings/BroadcastUserSettingsContent.dart';
import '../domains/messages/outgoing-messages/join-session/UserSettings.dart';
import '../domains/messages/outgoing-messages/update-session/UpdateSessionContent.dart';
import '../domains/messages/outgoing-messages/update-session/UpdateSessionMessage.dart';
import '../services/SocketMessengerService.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'NP+',
        theme: PartyHarderTheme.getLightTheme(),
        darkTheme: PartyHarderTheme.getDarkTheme(),
        home: AppContainer(
          title: 'NP+',
        ));
  }
}

class AppContainer extends StatefulWidget {
  final String title;
  AppContainer({Key key, @required this.title}) : super(key: key);

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

  // Video info
  int _videoDuration = 655550;
  // TODO: capture video id

  // Session
  //
  // State
  // TODO: know if session has been joined
  // Timers
  Timer _getServerTimeTimer;
  Timer _pingServerTimer;

  // App container state
  bool _isShowingChangelogDialog = false;

  // Landing state
  TextEditingController _urlTextController = TextEditingController();

  // Party state
  bool _isKeyboardVisible = false;
  UniqueKey chatUniqueKey = UniqueKey();

  _AppContainerState() {
    _setupLocalUserListener();
    _dispatchShowChangelogIntent();
  }

  void _setupLocalUserListener() {
    _localUserStore.stream$.listen(_onLocalUserChanged);
  }

  void _onLocalUserChanged(LocalUser localUser) {
    if (_partySessionStore.isSessionActive()) {
      _sendBroadcastUserSettingsMessage(localUser);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_partySessionStore.isSessionActive()) {
        _partyService.rejoinLastParty();
      }
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    KeyboardVisibilityNotification().addNewListener(
        onChange: (isVisible) => _isKeyboardVisible = isVisible);

    _loadLastPartyUrl();
  }

  void _loadLastPartyUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _urlTextController.text = prefs.getString("lastPartyUrl") ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: Theme.of(context).primaryColor,
        ),
        body: StreamBuilder(
          stream: _partySessionStore.stream$,
          builder: (context, AsyncSnapshot<PartySession> partySessionSnapshot) {
            return Stack(
              children: <Widget>[
                partySessionSnapshot.data.isSessionActive()
                    ? _getPartyPage()
                    : LandingPage(),
                Visibility(
                    visible: !_isKeyboardVisible,
                    child: SlidingUpPanel(
                      backdropEnabled: true,
                      parallaxEnabled: true,
                      maxHeight: 400,
                      minHeight: partySessionSnapshot.data.isSessionActive()
                          ? 100
                          : 80,
                      panelBuilder: (sc) => _panel(sc),
                      isDraggable: partySessionSnapshot.data.isSessionActive(),
                    ))
              ],
            );
          },
        ));
  }

  Widget _panel(ScrollController scrollController) {
    return MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: StreamBuilder(
            stream: _partySessionStore.stream$,
            builder:
                (context, AsyncSnapshot<PartySession> partySessionSnapshot) {
              if (partySessionSnapshot.data == null) {
                return Container();
              }
              return Container(
                color: Theme.of(context).bottomAppBarColor,
                child: ListView(
                  controller: scrollController,
                  children: <Widget>[
                    SizedBox(
                      height: 12.0,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Visibility(
                          visible: partySessionSnapshot.data.isSessionActive(),
                          child: Container(
                            width: 30,
                            height: 5,
                            decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(12.0))),
                          ),
                        )
                      ],
                    ),
                    SizedBox(
                      height: 8,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Visibility(
                          visible: partySessionSnapshot.data.isSessionActive(),
                          child: CupertinoButton(
                            child: Text(
                              "Disconnect",
                              style: TextStyle(
                                  color: Theme.of(context).primaryColor),
                            ),
                            onPressed: () {
                              _onDisconnectButtonPressed();
                            },
                          ),
                        ),
                        StreamBuilder(
                            stream: _localUserStore.stream$,
                            initialData: LocalUser(),
                            builder: (context, localUserSnapshot) {
                              LocalUser localUser = localUserSnapshot.data;
                              return IconButton(
                                icon: SvgPicture.asset(
                                    localUserSnapshot.data.icon != null
                                        ? 'assets/avatars/${localUser.icon}'
                                        : '',
                                    height: 85),
                                onPressed: () {
                                  _navigateToAccountSettings(context);
                                },
                              );
                            }),
                      ],
                    ),
                    SizedBox(
                      height: 5.0,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Visibility(
                          visible: partySessionSnapshot.data.isSessionActive(),
                          child: _getPlaybackControlButton(),
                        ),
                      ],
                    )
                  ],
                ),
              );
            }));
  }

  Widget _getPartyPage() {
    Size currentScreenSize = MediaQuery.of(context).size;
    double screenRatio = currentScreenSize.height / currentScreenSize.width;
    return SizedBox(
        height: MediaQuery.of(context).size.height - (105 * screenRatio),
        child: Padding(
          padding: EdgeInsets.fromLTRB(6, 0, 6, 0),
          child: ChatFeed(
            key: chatUniqueKey,
          ),
        ));
  }

  Widget _getPlaybackControlButton() {
    return StreamBuilder(
        stream: _playbackInfoStore.stream$,
        builder: (context, playbackInfoSnapshot) {
          return CupertinoButton(
              child: Icon(
                  playbackInfoSnapshot.hasData
                      ? (playbackInfoSnapshot.data.isPlaying
                          ? CupertinoIcons.pause_solid
                          : CupertinoIcons.play_arrow_solid)
                      : CupertinoIcons.play_arrow_solid,
                  size: 40),
              color: Theme.of(context).primaryColor,
              padding: EdgeInsets.fromLTRB(35, 0, 30, 4),
              minSize: 55,
              borderRadius: BorderRadius.circular(500),
              onPressed: playbackInfoSnapshot.hasData
                  ? (_playbackInfoStore.playbackInfo.isPlaying
                      ? _onPausePressed
                      : _onPlayPressed)
                  : _onPlayPressed);
        });
  }

  Future<void> _showChangelogDialog() async {
    await showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return ChangelogDialogFactory.getChangelogDialog(context);
        });
  }

  void _onDisconnectButtonPressed() {
    try {
      this._messenger.closeConnection();
      this._getServerTimeTimer.cancel();
      this._pingServerTimer.cancel();
    } on Exception {
      debugPrint("Failed to disconnect");
    }
    setState(() {
      _disconnect();
      _clearState();
    });
  }

  void _onPlayPressed() {
    _playbackInfoStore.updateAsPlaying();
    int estimatedServerTime = _partySessionStore.partySession
        .getServerTimeAdjustedForTimeSinceLastServerTimeUpdate();
    _updateSessionContent(
        VideoState.PLAYING,
        _playbackInfoStore.playbackInfo.lastKnownMoviePosition,
        estimatedServerTime);
    _playbackInfoStore.updateServerTimeAtLastUpdate(estimatedServerTime);
  }

  void _onPausePressed() {
    _playbackInfoStore.updateAsPaused();
    _playbackInfoStore.updateLastKnownMoviePosition(
        _getVideoPositionAdjustedForTimeSinceLastVideoStateUpdate());
    int estimatedServerTime = _partySessionStore.partySession
        .getServerTimeAdjustedForTimeSinceLastServerTimeUpdate();
    _updateSessionContent(
        VideoState.PAUSED,
        _playbackInfoStore.playbackInfo.lastKnownMoviePosition,
        estimatedServerTime);
    _playbackInfoStore.updateServerTimeAtLastUpdate(estimatedServerTime);
  }

  void _loadUserInfo() async {
    if (_partySessionStore.isSessionActive()) {
      _sendBroadcastUserSettingsMessage(_localUserStore.localUser);
    }
  }

  void _dispatchShowChangelogIntent() {
    Future.delayed(Duration(milliseconds: 300), () async {
      if (!_isShowingChangelogDialog) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String lastViewedChangelog =
            await prefs.getString("lastViewedChangelog");
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

  void _disconnect() {
    _messenger.closeConnection();
    _partySessionStore.setAsSessionInactive();
  }

  void _clearState() {
    setState(() {
      _partySessionStore.updateServerTime(0);
      _playbackInfoStore.updateServerTimeAtLastUpdate(0);
      _playbackInfoStore.updateLastKnownMoviePosition(0);
      _chatMessagesStore.pushNewChatMessages(List.from([]));
    });
  }

  void _navigateToAccountSettings(buildContext) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserSettingsPage()),
    );
    await _loadUserInfo();
  }

  int _getMillisecondsPassedSinceLastVideoStateUpdate() {
    return _getCurrentTimeMillisecondsSinceEpoch() -
        _playbackInfoStore.playbackInfo.serverTimeAtLastVideoStateUpdate;
  }

  int _getCurrentTimeMillisecondsSinceEpoch() {
    return DateTime.now().millisecondsSinceEpoch;
  }

  int _getVideoPositionAdjustedForTimeSinceLastVideoStateUpdate() {
    return _playbackInfoStore.playbackInfo.lastKnownMoviePosition +
        _getMillisecondsPassedSinceLastVideoStateUpdate();
  }

  void _updateSessionContent(
      String mediaState, int videoPosition, int lastKnownTimeUpdatedAt) {
    _messenger.sendMessage(UpdateSessionMessage(UpdateSessionContent(
        videoPosition,
        lastKnownTimeUpdatedAt,
        mediaState,
        null,
        null,
        _videoDuration,
        false)));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disconnect();
    _clearState();
    super.dispose();
  }
}
