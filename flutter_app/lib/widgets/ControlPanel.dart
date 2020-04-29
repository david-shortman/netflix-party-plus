import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:np_plus/GetItInstance.dart';
import 'package:np_plus/domains/playback/PlaybackInfo.dart';
import 'package:np_plus/services/PartyService.dart';
import 'package:np_plus/vaults/DefaultsVault.dart';
import 'package:np_plus/domains/media-controls/VideoState.dart';
import 'package:np_plus/domains/user/LocalUser.dart';
import 'package:np_plus/pages/UserSettingsPage.dart';
import 'package:np_plus/services/SocketMessengerService.dart';
import 'package:np_plus/store/LocalUserStore.dart';
import 'package:np_plus/store/PartySessionStore.dart';
import 'package:np_plus/store/PlaybackInfoStore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:seekbar/seekbar.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class ControlPanel extends StatefulWidget {
  ControlPanel({Key key}) : super(key: key);

  @override
  _ControlPanelState createState() => _ControlPanelState(key: key);
}

class _ControlPanelState extends State<ControlPanel> {
  final _partySessionStore = getIt.get<PartySessionStore>();
  final _localUserStore = getIt.get<LocalUserStore>();
  final _playbackInfoStore = getIt.get<PlaybackInfoStore>();
  final _messengerService = getIt.get<SocketMessengerService>();
  final _partyService = getIt.get<PartyService>();
  final _panelController = PanelController();
  final BehaviorSubject<double> _seekPercentage$ = BehaviorSubject.seeded(0.0);
  Timer _seekPercentageTimer;
  StreamSubscription<PlaybackInfo> _playbackInfoSubscription;
  double _lastActiveScrubbingPercentage = 0.0;
  bool _shouldUseLastActiveScrubbingPercentage = false;
  final BehaviorSubject<bool> _isPanelOpen = BehaviorSubject.seeded(false);
  double _lastPanelDirection = 0;

  _ControlPanelState({Key key});

  void _setupVideoPositionListener() {
    if (_playbackInfoSubscription == null) {
      _playbackInfoSubscription = _playbackInfoStore.stream$
          .distinct(_playbackInfoDistinct)
          .listen((playbackInfo) {
        _shouldUseLastActiveScrubbingPercentage = false;
        double progressPercentage = _getProgressPercentage(playbackInfo);
        _lastActiveScrubbingPercentage = progressPercentage;
        _seekPercentage$.add(progressPercentage);
        playbackInfo.isPlaying
            ? _restartVideoProgressTimer()
            : _stopVideoProgressTimer();
      });
    }
  }

  bool _playbackInfoDistinct(
      PlaybackInfo playbackInfo, PlaybackInfo newPlaybackInfo) {
    return playbackInfo.videoDuration == newPlaybackInfo.videoDuration &&
        playbackInfo.lastKnownMoviePosition ==
            newPlaybackInfo.lastKnownMoviePosition &&
        playbackInfo.isPlaying == newPlaybackInfo.isPlaying;
  }

  double _getProgressPercentage(PlaybackInfo playbackInfo) {
    return (playbackInfo.lastKnownMoviePosition ?? 0.0) *
        1.0 /
        (playbackInfo.videoDuration ?? 1.0) *
        1.0;
  }

  @override
  Widget build(BuildContext context) {
    _setupVideoPositionListener();

    return StreamBuilder(
        stream: _partySessionStore.isSessionActive$,
        builder: (context, AsyncSnapshot<bool> isSessionActiveSnapshot) {
          bool isSessionActive = isSessionActiveSnapshot.data ?? false;
          return SlidingUpPanel(
            collapsed: isSessionActive ? _collapsed(isSessionActive) : null,
            backdropEnabled: true,
            parallaxEnabled: true,
            controller: _panelController,
            maxHeight: isSessionActive ? 280 : 80,
            minHeight: isSessionActive ? 120 : 80,
            panel: _panel(isSessionActive),
            isDraggable: isSessionActive,
            onPanelOpened: () {
              _isPanelOpen.add(true);
            },
            onPanelSlide: (direction) {
              if (direction < _lastPanelDirection) {
                _isPanelOpen.add(false);
              }
              _lastPanelDirection = direction;
            },
            onPanelClosed: () {
              _isPanelOpen.add(false);
            },
          );
        });
  }

  Widget _collapsed(bool isSessionActive) {
    return StreamBuilder(
      stream: _isPanelOpen.stream,
      builder: (context, AsyncSnapshot<bool> isPanelOpenSnapshot) {
        bool isPanelOpen = isPanelOpenSnapshot.data ?? false;
        return Visibility(
            visible: !isPanelOpen,
            child: Container(
                color: Theme.of(context).bottomAppBarColor,
                child: Column(
                  children: <Widget>[
                    SizedBox(
                      height: 12.0,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Visibility(
                          visible: isSessionActive,
                          child: Container(
                            width: 30,
                            height: 5,
                            decoration: BoxDecoration(
                                color: Colors.grey,
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
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          _getPlaybackControlButton(),
                          CupertinoButton(
                            child: Icon(
                              Icons.replay_10,
                              color: Theme.of(context).primaryColor,
                              size: 45,
                            ),
                            onPressed: _onReplay10Pressed,
                          ),
                          CupertinoButton(
                              child: Icon(
                                Icons.forward_10,
                                color: Theme.of(context).primaryColor,
                                size: 45,
                              ),
                              onPressed: _onForward10Pressed),
                        ]),
                  ],
                )));
      },
    );
  }

  Widget _panel(bool isSessionActive) {
    return MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: Container(
          color: Theme.of(context).bottomAppBarColor,
          child: Column(
            children: <Widget>[
              SizedBox(
                height: 12.0,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Visibility(
                    visible: isSessionActive,
                    child: Container(
                      width: 30,
                      height: 5,
                      decoration: BoxDecoration(
                          color: Colors.grey,
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
                    visible: isSessionActive,
                    child: CupertinoButton(
                      child: Text(
                        "Disconnect",
                        style: TextStyle(color: Theme.of(context).primaryColor),
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
                                  ? 'assets/avatars/${localUser?.icon ?? DefaultsVault.DEFAULT_AVATAR}'
                                  : 'assets/avatars/Batman.svg',
                              height: 85),
                          onPressed: () {
                            _navigateToAccountSettings(context);
                          },
                        );
                      }),
                ],
              ),
              SizedBox(
                height: 15.0,
              ),
              Visibility(
                  visible: isSessionActive,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        CupertinoButton(
                          child: Icon(
                            Icons.replay_10,
                            color: Theme.of(context).primaryColor,
                            size: 45,
                          ),
                          onPressed: _onReplay10Pressed,
                        ),
                        _getPlaybackControlButton(),
                        CupertinoButton(
                            child: Icon(
                              Icons.forward_10,
                              color: Theme.of(context).primaryColor,
                              size: 45,
                            ),
                            onPressed: _onForward10Pressed),
                      ])),
              SizedBox(
                height: 20.0,
              ),
              Visibility(
                  visible: isSessionActive,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                    child: StreamBuilder(
                      stream: _seekPercentage$.stream,
                      builder: (context, seekPercentageSnapshot) {
                        double seekPercentage =
                            seekPercentageSnapshot.data ?? 0.0;
                        return SeekBar(
                          thumbRadius: 20.0,
                          progressWidth: 4,
                          thumbColor: Theme.of(context).primaryColor,
                          barColor:
                              Theme.of(context).brightness == Brightness.light
                                  ? Colors.grey[350]
                                  : Colors.white,
                          value: _shouldUseLastActiveScrubbingPercentage
                              ? _lastActiveScrubbingPercentage
                              : seekPercentage,
                          progressColor: Theme.of(context).primaryColor,
                          onProgressChanged: (seekPercentage) {
                            _lastActiveScrubbingPercentage = seekPercentage;
                          },
                          onStartTrackingTouch: () {
                            _shouldUseLastActiveScrubbingPercentage = true;
                            _stopVideoProgressTimer();
                            _playbackInfoSubscription.pause();
                            setState(() {
                              _lastActiveScrubbingPercentage =
                                  ((_playbackInfoStore.playbackInfo
                                                  .lastKnownMoviePosition ??
                                              0) /
                                          (_playbackInfoStore
                                                  .playbackInfo.videoDuration ??
                                              0)) *
                                      1.0;
                            });
                          },
                          onStopTrackingTouch: () {
                            _playbackInfoSubscription.resume();
                            setState(() {
                              _shouldUseLastActiveScrubbingPercentage = false;
                            });
                            _restartVideoProgressTimer();
                            _partyService.updateVideoState(
                                _playbackInfoStore.getVideoState(),
                                percentage: _lastActiveScrubbingPercentage);
                          },
                        );
                      },
                    ),
                  ))
            ],
          ),
        ));
  }

  void _onReplay10Pressed() {
    HapticFeedback.lightImpact();
    _partyService.updateVideoState(_playbackInfoStore.getVideoState(),
        diff: -10000);
  }

  void _onForward10Pressed() {
    HapticFeedback.lightImpact();
    _partyService.updateVideoState(_playbackInfoStore.getVideoState(),
        diff: 10000);
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

  void _onDisconnectButtonPressed() {
    try {
      _messengerService.closeConnection();
    } on Exception {
      debugPrint("Failed to disconnect");
    }
    _panelController.close();
    _messengerService.closeConnection();
    _partySessionStore.setAsSessionInactive();
  }

  void _onPlayPressed() {
    HapticFeedback.lightImpact();
    _partyService.updateVideoState(VideoState.PLAYING);
  }

  void _onPausePressed() {
    HapticFeedback.lightImpact();
    _partyService.updateVideoState(VideoState.PAUSED);
  }

  void _navigateToAccountSettings(buildContext) async {
    await _panelController.close();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserSettingsPage()),
    );
  }

  void _stopVideoProgressTimer() {
    if (_seekPercentageTimer != null) {
      _seekPercentageTimer.cancel();
    }
  }

  void _restartVideoProgressTimer() {
    _stopVideoProgressTimer();
    if (_playbackInfoStore.getVideoState() == VideoState.PLAYING) {
      _seekPercentageTimer = Timer.periodic(Duration(seconds: 1), (_) {
        _lastActiveScrubbingPercentage = _lastActiveScrubbingPercentage +
            (1000 / _playbackInfoStore.playbackInfo.videoDuration);
        _seekPercentage$.add(_lastActiveScrubbingPercentage);
      });
    }
  }
}
