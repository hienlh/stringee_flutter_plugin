import 'dart:developer';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:stringee_flutter_plugin/stringee_flutter_plugin.dart';

StringeeCall _stringeeCall;
StringeeCall2 _stringeeCall2;

class Call extends StatefulWidget {
  final String toUserId;
  final String fromUserId;
  final StringeeCall incomingCall;
  final StringeeCall2 incomingCall2;
  final String callId;
  final StringeeObjectEventType callType;
  final bool showIncomingUi;
  final bool hasLocalStream;
  final bool hasRemoteStream;
  final bool isVideoCall;
  final bool isResumeVideo = false;
  final bool isMirror = true;

  Call({
    Key key,
    @required this.fromUserId,
    @required this.toUserId,
    this.showIncomingUi = false,
    this.isVideoCall = false,
    this.callType,
    this.incomingCall2,
    this.incomingCall,
    this.callId,
    this.hasLocalStream = false,
    this.hasRemoteStream = false,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _CallState();
  }
}

class _CallState extends State<Call> {
  String status = "";
  bool isSpeaker = false;
  bool showIncomingUi;
  bool hasLocalStream = false;
  bool hasRemoteStream = false;
  String callId;

  @override
  void initState() {
    super.initState();

    isSpeaker = widget.isVideoCall;
    showIncomingUi = widget.showIncomingUi;
    hasLocalStream = widget.hasLocalStream;
    hasRemoteStream = widget.hasRemoteStream;
    callId = widget.callId;

    if (widget.callType == StringeeObjectEventType.call) {
      _makeOrInitAnswerCall();
    } else {
      _makeOrInitAnswerCall2();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget nameCalling = Container(
      alignment: Alignment.topCenter,
      padding: EdgeInsets.only(top: 120.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            alignment: Alignment.center,
            padding: EdgeInsets.only(bottom: 15.0),
            child: Text(
              "${widget.toUserId}",
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.0,
              ),
            ),
          ),
          Container(
            alignment: Alignment.center,
            child: Text(
              '$status',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.0,
              ),
            ),
          )
        ],
      ),
    );

    Widget bottomContainer = Container(
      padding: EdgeInsets.only(bottom: 30.0),
      alignment: Alignment.bottomCenter,
      child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: widget.showIncomingUi
              ? <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      GestureDetector(
                        onTap: _rejectCallTapped,
                        child: Image.asset(
                          'images/end.png',
                          height: 75.0,
                          width: 75.0,
                        ),
                      ),
                      GestureDetector(
                        onTap: _acceptCallTapped,
                        child: Image.asset(
                          'images/answer.png',
                          height: 75.0,
                          width: 75.0,
                        ),
                      ),
                    ],
                  )
                ]
              : <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      ButtonSpeaker(isSpeaker: widget.isVideoCall),
                      ButtonMicro(isMute: false),
                      ButtonVideo(isVideoEnable: widget.isVideoCall),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.only(top: 20.0, bottom: 20.0),
                    child: GestureDetector(
                      onTap: _endCallTapped,
                      child: Image.asset(
                        'images/end.png',
                        height: 75.0,
                        width: 75.0,
                      ),
                    ),
                  )
                ]),
    );

    Widget localView = (widget.hasLocalStream)
        ? StringeeVideoView(
            widget.callId,
            true,
            color: Colors.white,
            alignment: Alignment.topRight,
            isOverlay: true,
            isMirror: widget.isMirror,
            margin: EdgeInsets.only(top: 100.0, right: 25.0),
            height: 200.0,
            width: 150.0,
            scalingType: ScalingType.fill,
          )
        : Placeholder();

    Widget remoteView = (widget.hasRemoteStream)
        ? StringeeVideoView(
            widget.callId,
            false,
            color: Colors.blue,
            isOverlay: false,
            isMirror: false,
            scalingType: ScalingType.fill,
          )
        : Placeholder();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          remoteView,
          localView,
          nameCalling,
          bottomContainer,
          ButtonSwitchCamera(
            isMirror: widget.isMirror,
          ),
        ],
      ),
    );
  }

  Future _makeOrInitAnswerCall() async {
    // Gán cuộc gọi đến cho biến global
    _stringeeCall = widget.incomingCall;

    if (!widget.showIncomingUi) {
      _stringeeCall = StringeeCall();
    }

    // Listen events
    _stringeeCall.eventStreamController.stream.listen((event) {
      Map<dynamic, dynamic> map = event;
      log("Call " + map.toString());
      switch (map['eventType']) {
        case StringeeCallEvents.didChangeSignalingState:
          handleSignalingStateChangeEvent(map['body']);
          break;
        case StringeeCallEvents.didChangeMediaState:
          handleMediaStateChangeEvent(map['body']);
          break;
        case StringeeCallEvents.didReceiveCallInfo:
          handleReceiveCallInfoEvent(map['body']);
          break;
        case StringeeCallEvents.didHandleOnAnotherDevice:
          handleHandleOnAnotherDeviceEvent(map['body']);
          break;
        case StringeeCallEvents.didReceiveLocalStream:
          handleReceiveLocalStreamEvent(map['body']);
          break;
        case StringeeCallEvents.didReceiveRemoteStream:
          handleReceiveRemoteStreamEvent(map['body']);
          break;
        case StringeeCallEvents.didChangeAudioDevice:
          if (Platform.isAndroid) {
            handleChangeAudioDeviceEvent(
                map['selectedAudioDevice'], _stringeeCall, null);
          }
          break;
        default:
          break;
      }
    });

    if (widget.showIncomingUi) {
      _stringeeCall.initAnswer().then((event) {
        bool status = event['status'];
        if (!status) {
          clearDataEndDismiss();
        }
      });
    } else {
      final parameters = {
        'from': widget.fromUserId,
        'to': widget.toUserId,
        'isVideoCall': widget.isVideoCall,
        'customData': null,
        'videoQuality': VideoQuality.fullHd,
      };

      _stringeeCall.makeCall(parameters).then((result) {
        bool status = result['status'];
        int code = result['code'];
        String message = result['message'];
        log('MakeCall CallBack --- $status - $code - $message - ${_stringeeCall.id} - ${_stringeeCall.from} - ${_stringeeCall.to}');
        if (!status) {
          Navigator.pop(context);
        }
      });
    }
  }

  Future _makeOrInitAnswerCall2() async {
    // Gán cuộc gọi đến cho biến global
    _stringeeCall2 = widget.incomingCall2;

    if (!widget.showIncomingUi) {
      _stringeeCall2 = StringeeCall2();
    }

    // Listen events
    _stringeeCall2.eventStreamController.stream.listen((event) {
      Map<dynamic, dynamic> map = event;
      switch (map['eventType']) {
        case StringeeCall2Events.didChangeSignalingState:
          handleSignalingStateChangeEvent(map['body']);
          break;
        case StringeeCall2Events.didChangeMediaState:
          handleMediaStateChangeEvent(map['body']);
          break;
        case StringeeCall2Events.didReceiveCallInfo:
          handleReceiveCallInfoEvent(map['body']);
          break;
        case StringeeCall2Events.didHandleOnAnotherDevice:
          handleHandleOnAnotherDeviceEvent(map['body']);
          break;
        case StringeeCall2Events.didReceiveLocalStream:
          handleReceiveLocalStreamEvent(map['body']);
          break;
        case StringeeCall2Events.didReceiveRemoteStream:
          handleReceiveRemoteStreamEvent(map['body']);
          break;
        case StringeeCall2Events.didChangeAudioDevice:
          if (Platform.isAndroid) {
            handleChangeAudioDeviceEvent(
                map['selectedAudioDevice'], null, _stringeeCall2);
          }
          break;
        default:
          break;
      }
    });

    if (widget.showIncomingUi) {
      _stringeeCall2.initAnswer().then((event) {
        bool status = event['status'];
        if (!status) {
          clearDataEndDismiss();
        }
      });
    } else {
      final parameters = {
        'from': widget.fromUserId,
        'to': widget.toUserId,
        'isVideoCall': widget.isVideoCall,
        'customData': null,
        'videoQuality': VideoQuality.fullHd,
      };

      _stringeeCall2.makeCall(parameters).then((result) {
        bool status = result['status'];
        int code = result['code'];
        String message = result['message'];
        log('MakeCall CallBack --- $status - $code - $message - ${_stringeeCall2.id} - ${_stringeeCall2.from} - ${_stringeeCall2.to}');
        if (!status) {
          Navigator.pop(context);
        }
      });
    }
  }

  void _endCallTapped() {
    switch (widget.callType) {
      case StringeeObjectEventType.call:
        _stringeeCall.hangup().then((result) {
          log('_endCallTapped -- ${result['message']}');
          bool status = result['status'];
          if (status) {
            if (Platform.isAndroid) {
              clearDataEndDismiss();
            }
          }
        });
        break;
      case StringeeObjectEventType.call2:
        _stringeeCall2.hangup().then((result) {
          log('_endCallTapped -- ${result['message']}');
          bool status = result['status'];
          if (status) {
            if (Platform.isAndroid) {
              clearDataEndDismiss();
            }
          }
        });
        break;
      case StringeeObjectEventType.client:
        break;
    }
  }

  void _acceptCallTapped() {
    switch (widget.callType) {
      case StringeeObjectEventType.call:
        _stringeeCall.answer().then((result) {
          log('_acceptCallTapped -- ${result['message']}');
          bool status = result['status'];
          if (!status) {
            clearDataEndDismiss();
          }
        });
        break;
      case StringeeObjectEventType.call2:
        _stringeeCall2.answer().then((result) {
          log('_acceptCallTapped -- ${result['message']}');
          bool status = result['status'];
          if (!status) {
            clearDataEndDismiss();
          }
        });
        break;
      case StringeeObjectEventType.client:
        break;
    }
    setState(() {
      showIncomingUi = !widget.showIncomingUi;
    });
  }

  void _rejectCallTapped() {
    switch (widget.callType) {
      case StringeeObjectEventType.call:
        _stringeeCall.reject().then((result) {
          log('_rejectCallTapped -- ${result['message']}');
          if (Platform.isAndroid) {
            clearDataEndDismiss();
          }
        });
        break;
      case StringeeObjectEventType.call2:
        _stringeeCall2.reject().then((result) {
          log('_rejectCallTapped -- ${result['message']}');
          if (Platform.isAndroid) {
            clearDataEndDismiss();
          }
        });
        break;
      case StringeeObjectEventType.client:
        break;
    }
  }

  void handleSignalingStateChangeEvent(StringeeSignalingState state) {
    log('handleSignalingStateChangeEvent - $state');
    setState(() {
      status = state.toString().split('.')[1];
    });
    switch (state) {
      case StringeeSignalingState.calling:
        break;
      case StringeeSignalingState.ringing:
        break;
      case StringeeSignalingState.answered:
        break;
      case StringeeSignalingState.busy:
        clearDataEndDismiss();
        break;
      case StringeeSignalingState.ended:
        clearDataEndDismiss();
        break;
      default:
        break;
    }
  }

  void handleMediaStateChangeEvent(StringeeMediaState state) {
    log('handleMediaStateChangeEvent - $state');
    setState(() {
      status = state.toString().split('.')[1];
    });
    switch (state) {
      case StringeeMediaState.connected:
        break;
      case StringeeMediaState.disconnected:
        break;
      default:
        break;
    }
  }

  void handleReceiveCallInfoEvent(Map<dynamic, dynamic> info) {
    log('handleReceiveCallInfoEvent - $info');
  }

  void handleHandleOnAnotherDeviceEvent(StringeeSignalingState state) {
    log('handleHandleOnAnotherDeviceEvent - $state');
  }

  void handleReceiveLocalStreamEvent(String callId) {
    log('handleReceiveLocalStreamEvent - $callId');
    setState(() {
      hasLocalStream = true;
      callId = callId;
    });
  }

  void handleReceiveRemoteStreamEvent(String callId) {
    log('handleReceiveRemoteStreamEvent - $callId');
    setState(() {
      hasRemoteStream = true;
      callId = callId;
    });
  }

  void handleChangeAudioDeviceEvent(
      AudioDevice audioDevice, StringeeCall call, StringeeCall2 call2) {
    log('handleChangeAudioDeviceEvent - $audioDevice');
    switch (audioDevice) {
      case AudioDevice.speakerPhone:
      case AudioDevice.earpiece:
        if (call != null) {
          call.setSpeakerphoneOn(isSpeaker);
        }
        if (call2 != null) {
          call2.setSpeakerphoneOn(isSpeaker);
        }
        break;
      case AudioDevice.bluetooth:
      case AudioDevice.wiredHeadset:
        isSpeaker = false;
        if (call != null) {
          call.setSpeakerphoneOn(isSpeaker);
        }
        if (call2 != null) {
          call2.setSpeakerphoneOn(isSpeaker);
        }
        break;
      case AudioDevice.none:
        log('handleChangeAudioDeviceEvent - non audio devices connected');
        break;
    }
  }

  void clearDataEndDismiss() {
    if (_stringeeCall != null) {
      _stringeeCall.destroy();
      _stringeeCall = null;
      Navigator.pop(context);
    } else if (_stringeeCall2 != null) {
      _stringeeCall2.destroy();
      _stringeeCall2 = null;
      Navigator.pop(context);
    } else {
      Navigator.pop(context);
    }
  }
}

class ButtonSwitchCamera extends StatefulWidget {
  final bool isMirror;

  ButtonSwitchCamera({
    Key key,
    this.isMirror,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ButtonSwitchCameraState();
}

class _ButtonSwitchCameraState extends State<ButtonSwitchCamera> {
  bool isMirror = false;

  initState() {
    super.initState();
    isMirror = widget.isMirror;
  }

  void _toggleSwitchCamera() {
    if (_stringeeCall != null) {
      isMirror = !widget.isMirror;
      _stringeeCall.switchCamera(widget.isMirror).then((result) {
        bool status = result['status'];
        if (status) {}
      });
    } else {
      isMirror = !widget.isMirror;
      _stringeeCall2.switchCamera(widget.isMirror).then((result) {
        bool status = result['status'];
        if (status) {}
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: EdgeInsets.only(left: 50.0, top: 50.0),
        child: GestureDetector(
          onTap: _toggleSwitchCamera,
          child: Image.asset(
            'images/switch_camera.png',
            height: 30.0,
            width: 30.0,
          ),
        ),
      ),
    );
  }
}

class ButtonSpeaker extends StatefulWidget {
  final bool isSpeaker;

  ButtonSpeaker({
    Key key,
    @required this.isSpeaker,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ButtonSpeakerState();
}

class _ButtonSpeakerState extends State<ButtonSpeaker> {
  bool _isSpeaker;

  void _toggleSpeaker() {
    if (_stringeeCall != null) {
      _stringeeCall.setSpeakerphoneOn(!_isSpeaker).then((result) {
        bool status = result['status'];
        if (status) {
          setState(() {
            _isSpeaker = !_isSpeaker;
          });
        }
      });
    } else {
      _stringeeCall2.setSpeakerphoneOn(!_isSpeaker).then((result) {
        bool status = result['status'];
        if (status) {
          setState(() {
            _isSpeaker = !_isSpeaker;
          });
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _isSpeaker = widget.isSpeaker;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleSpeaker,
      child: Image.asset(
        _isSpeaker ? 'images/ic_speaker_off.png' : 'images/ic_speaker_on.png',
        height: 75.0,
        width: 75.0,
      ),
    );
  }
}

class ButtonMicro extends StatefulWidget {
  final bool isMute;

  ButtonMicro({
    Key key,
    @required this.isMute,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ButtonMicroState();
}

class _ButtonMicroState extends State<ButtonMicro> {
  bool _isMute;

  void _toggleMicro() {
    if (_stringeeCall != null) {
      _stringeeCall.mute(!_isMute).then((result) {
        bool status = result['status'];
        if (status) {
          setState(() {
            _isMute = !_isMute;
          });
        }
      });
    } else {
      _stringeeCall2.mute(!_isMute).then((result) {
        bool status = result['status'];
        if (status) {
          setState(() {
            _isMute = !_isMute;
          });
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _isMute = widget.isMute;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleMicro,
      child: Image.asset(
        _isMute ? 'images/ic_mute.png' : 'images/ic_mic.png',
        height: 75.0,
        width: 75.0,
      ),
    );
  }
}

class ButtonVideo extends StatefulWidget {
  final bool isVideoEnable;

  ButtonVideo({
    Key key,
    @required this.isVideoEnable,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ButtonVideoState();
}

class _ButtonVideoState extends State<ButtonVideo> {
  bool _isVideoEnable;

  void _toggleVideo() {
    if (_stringeeCall != null) {
      _stringeeCall.enableVideo(!_isVideoEnable).then((result) {
        bool status = result['status'];
        if (status) {
          setState(() {
            _isVideoEnable = !_isVideoEnable;
          });
        }
      });
    } else {
      _stringeeCall2.enableVideo(!_isVideoEnable).then((result) {
        bool status = result['status'];
        if (status) {
          setState(() {
            _isVideoEnable = !_isVideoEnable;
          });
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _isVideoEnable = widget.isVideoEnable;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isVideoEnable ? _toggleVideo : null,
      child: Image.asset(
        _isVideoEnable ? 'images/ic_video.png' : 'images/ic_video_off.png',
        height: 75.0,
        width: 75.0,
      ),
    );
  }
}
