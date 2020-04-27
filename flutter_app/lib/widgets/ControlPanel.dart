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
import 'package:np_plus/domains/server/ServerInfo.dart';
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
  bool _isScrubbingSeekBar = false;
  final BehaviorSubject<double> _seekPercentage$ = BehaviorSubject.seeded(0.0);
  Timer _seekPercentageTimer;
  StreamSubscription<PlaybackInfo> _playbackInfoSubscription;
  double _lastActiveScrubbingPercentage = 0.0;
  bool _shouldUseLastActiveScrubbingPercentage = false;

  _ControlPanelState({Key key}) {
    _setupVideoPositionListener();
  }

  void _setupVideoPositionListener() {
    _playbackInfoSubscription = _playbackInfoStore.stream$.listen((playbackInfo) {
      _shouldUseLastActiveScrubbingPercentage = false;
      _seekPercentage$.add(((playbackInfo.lastKnownMoviePosition ?? 0) / (playbackInfo.videoDuration ?? 0)) * 1.0);
      playbackInfo.isPlaying ? _startVideoProgressTimer() : _stopVideoProgressTimer();
    });
  }

  @override
  Widget build(BuildContext context) {

    return StreamBuilder(
        stream: _partySessionStore.stream$,
        builder: (context, AsyncSnapshot<PartySession> partySessionSnapshot) {
          bool isSessionActive = partySessionSnapshot.data != null &&
              partySessionSnapshot.data.isSessionActive();
          return SlidingUpPanel(
            backdropEnabled: true,
            parallaxEnabled: true,
            controller: _panelController,
            maxHeight: isSessionActive ? 280 : 80,
            minHeight: isSessionActive ? 100 : 80,
            panelBuilder: (sc) => _panel(sc, isSessionActive),
            isDraggable: isSessionActive && !_isScrubbingSeekBar,
          );
        });
  }

  Widget _panel(ScrollController scrollController, bool isSessionActive) {
    return MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: Container(
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
                    visible: isSessionActive,
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
                height: 5.0,
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
                      double seekPercentage = seekPercentageSnapshot.data ?? 0.0;
                      return SeekBar(
                        thumbRadius: 20.0,
                        progressWidth: 4,
                        thumbColor: Theme.of(context).primaryColor,
                        value: _shouldUseLastActiveScrubbingPercentage ? _lastActiveScrubbingPercentage : seekPercentage,
                        progressColor: Theme.of(context).primaryColor,
                        onProgressChanged: (seekPercentage) {
                          _lastActiveScrubbingPercentage = seekPercentage;
                        },
                        onStartTrackingTouch: () {
                          _shouldUseLastActiveScrubbingPercentage = true;
                          _stopVideoProgressTimer();
                          _playbackInfoSubscription.cancel();
                          setState(() {
                            _isScrubbingSeekBar = true;
                            _lastActiveScrubbingPercentage = ((_playbackInfoStore.playbackInfo.lastKnownMoviePosition ?? 0) / (_playbackInfoStore.playbackInfo.videoDuration ?? 0)) * 1.0;
                          });
                        },
                        onStopTrackingTouch: () {
                          _setupVideoPositionListener();
                          _startVideoProgressTimer();
                          setState(() {
                            _isScrubbingSeekBar = false;
                          });
                          _partyService.updateVideoState(_playbackInfoStore.getVideoState(), percentage: _lastActiveScrubbingPercentage);
                        },
                      );
                    },
                  ),
                )
              )
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

  void _startVideoProgressTimer() {
    if (_playbackInfoStore.getVideoState() == VideoState.PLAYING) {
      _stopVideoProgressTimer();
      _seekPercentageTimer = Timer.periodic(Duration(seconds: 1), (_) {
        int videoDuration = _playbackInfoStore.playbackInfo.videoDuration ?? 0;
        double percentageIncrementedByOneSecond = ((_seekPercentage$.value ?? 0.0) * videoDuration + 1000) / videoDuration;
        debugPrint(percentageIncrementedByOneSecond.toString());
        setState(() {
          _seekPercentage$.add(percentageIncrementedByOneSecond);
        });
      });
    }
  }
}
