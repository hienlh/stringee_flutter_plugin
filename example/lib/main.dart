import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission/permission.dart';
import 'package:stringee_flutter_plugin/stringee_flutter_plugin.dart';
import 'package:stringee_flutter_plugin_example/Chat.dart';

import 'Call.dart';

StringeeClient _client = StringeeClient();

String strUserId = "";

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: "OneToOneCallSample", home: MyHomePage());
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MyHomePageState();
  }
}

class _MyHomePageState extends State<MyHomePage> {
  String token;
  String myUserId = 'Not connected';
  bool isAppInBackground = false;

  @override
  void initState() {
    super.initState();
    (() async {
      if (Platform.isAndroid) {
        await requestPermissions();
      }

      /// Lắng nghe sự kiện của StringeeClient(kết nối, cuộc gọi đến...)
      _client.eventStreamController.stream.listen((event) {
        Map<dynamic, dynamic> map = event;
        switch (map['eventType']) {
          case StringeeClientEvents.didConnect:
            handleDidConnectEvent();
            break;
          case StringeeClientEvents.didDisconnect:
            handleDiddisconnectEvent();
            break;
          case StringeeClientEvents.didFailWithError:
            handleDidFailWithErrorEvent(
                map['body']['code'], map['body']['message']);
            break;
          case StringeeClientEvents.requestAccessToken:
            handleRequestAccessTokenEvent();
            break;
          case StringeeClientEvents.didReceiveCustomMessage:
            handleDidReceiveCustomMessageEvent(map['body']);
            break;
          case StringeeClientEvents.incomingCall:
            StringeeCall call = map['body'];
            handleIncomingCallEvent(call);
            break;
          case StringeeClientEvents.incomingCall2:
            StringeeCall2 call = map['body'];
            handleIncomingCall2Event(call);
            break;
          case StringeeClientEvents.didReceiveObjectChange:
            StringeeObjectChange objectChange = map['body'];
            print(objectChange.objectType.toString() +
                '\t' +
                objectChange.type.toString());
            print(objectChange.objects.toString());
            break;
          default:
            break;
        }
      });

      /// Connect
      _client.connect(token);
    })();
  }

  Future requestPermissions() async {
    List<PermissionName> permissionNames = [];
    permissionNames.add(PermissionName.Camera);
    permissionNames.add(PermissionName.Contacts);
    permissionNames.add(PermissionName.Microphone);
    permissionNames.add(PermissionName.Location);
    permissionNames.add(PermissionName.Storage);
    permissionNames.add(PermissionName.State);
    permissionNames.add(PermissionName.Internet);
    var permissions = await Permission.requestPermissions(permissionNames);
    permissions.forEach((permission) {});
  }

  @override
  Widget build(BuildContext context) {
    Widget topText = Container(
      padding: EdgeInsets.only(left: 10.0, top: 10.0),
      child: Text(
        'Connected as: $myUserId',
        style: TextStyle(
          color: Colors.black,
          fontSize: 20.0,
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text("OneToOneCallSample"),
        backgroundColor: Colors.indigo[600],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            topText,
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(20.0),
                    child: TextField(
                      onChanged: (String value) {
                        token = value;
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter your token here',
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                RaisedButton(
                  color: Colors.grey[300],
                  textColor: Colors.black,
                  onPressed: () {
                    _client.disconnect();
                    _client.connect(token);
                  },
                  child: Text('Login'),
                ),
              ],
            ),
            MyForm(),
          ],
        ),
      ),
    );
  }

  //region Handle Client Event
  void handleDidConnectEvent() {
    setState(() {
      myUserId = _client.userId;
    });
  }

  void handleDiddisconnectEvent() {
    setState(() {
      myUserId = 'Not connected';
    });
  }

  void handleDidFailWithErrorEvent(int code, String message) {
    print('code: ' + code.toString() + '\nmessage: ' + message);
  }

  void handleRequestAccessTokenEvent() {
    print('Request new access token');
  }

  void handleDidReceiveCustomMessageEvent(Map<dynamic, dynamic> map) {
    print('from: ' + map['fromUserId'] + '\nmessage: ' + map['message']);
  }

  void handleIncomingCallEvent(StringeeCall call) {
    showCallScreen(call, null);
  }

  void handleIncomingCall2Event(StringeeCall2 call) {
    showCallScreen(null, call);
  }

  void showCallScreen(StringeeCall call, StringeeCall2 call2) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Call(
          fromUserId: call != null ? call.from : call2.from,
          toUserId: call != null ? call.to : call2.to,
          isVideoCall: call != null ? call.isVideoCall : call2.isVideoCall,
          callType: call != null
              ? StringeeObjectEventType.call
              : StringeeObjectEventType.call2,
          showIncomingUi: true,
          incomingCall2: call != null ? null : call2,
          incomingCall: call != null ? call : null,
        ),
      ),
    );
  }
//endregion
}

class MyForm extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MyFormState();
  }
}

class _MyFormState extends State<MyForm> {
  @override
  Widget build(BuildContext context) {
    return Form(
//      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(20.0),
            child: TextField(
              onChanged: (String value) {
                _changeText(value);
              },
              decoration: InputDecoration(
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                ),
              ),
            ),
          ),
          Container(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 40.0,
                          width: 175.0,
                          child: RaisedButton(
                            color: Colors.grey[300],
                            textColor: Colors.black,
                            onPressed: () {
                              _callTapped(false, StringeeObjectEventType.call);
                            },
                            child: Text('CALL'),
                          ),
                        ),
                        Container(
                          height: 40.0,
                          width: 175.0,
                          margin: EdgeInsets.only(top: 20.0),
                          child: RaisedButton(
                            color: Colors.grey[300],
                            textColor: Colors.black,
                            onPressed: () {
                              _callTapped(true, StringeeObjectEventType.call);
                            },
                            child: Text('VIDEOCALL'),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 40.0,
                          width: 175.0,
                          child: RaisedButton(
                            color: Colors.grey[300],
                            textColor: Colors.black,
                            padding: EdgeInsets.only(left: 20.0, right: 20.0),
                            onPressed: () {
                              _callTapped(false, StringeeObjectEventType.call2);
                            },
                            child: Text('CALL2'),
                          ),
                        ),
                        Container(
                          height: 40.0,
                          width: 175.0,
                          margin: EdgeInsets.only(top: 20.0),
                          child: RaisedButton(
                            color: Colors.grey[300],
                            textColor: Colors.black,
                            padding: EdgeInsets.only(left: 20.0, right: 20.0),
                            onPressed: () {
                              _callTapped(true, StringeeObjectEventType.call2);
                            },
                            child: Text('VIDEOCALL2'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  height: 40.0,
                  width: 175.0,
                  margin: EdgeInsets.only(top: 20.0),
                  child: RaisedButton(
                    color: Colors.grey[300],
                    textColor: Colors.black,
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => Chat(
                                    client: _client,
                                  )));
                    },
                    child: Text('CHAT'),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _changeText(String val) {
    setState(() {
      strUserId = val;
    });
  }

  void _callTapped(bool isVideoCall, StringeeObjectEventType callType) {
    if (strUserId.isEmpty || !_client.hasConnected) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Call(
          fromUserId: _client.userId,
          toUserId: strUserId,
          isVideoCall: isVideoCall,
          callType: callType,
          showIncomingUi: false,
          hasLocalStream: true,
          hasRemoteStream: true,
        ),
      ),
    );
  }
}
