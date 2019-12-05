import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'character_controller.dart';
import 'login_character.dart';
import 'signin_button.dart';
import 'theme.dart';
import 'tracking_text_input.dart';

void main() {
  debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;

  const MyHomePage({Key key, this.title}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final CharacterController _characterController =
      CharacterController(projectGaze: LoginCharacter.projectGaze);
      
  String _password;
  @override
  Widget build(BuildContext context) {
    EdgeInsets devicePadding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(93, 142, 155, 1.0),
      body: Container(
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  // Box decoration takes a gradient
                  gradient: LinearGradient(
                    // Where the linear gradient begins and ends
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    // Add one stop for each color. Stops should increase from 0
                    // to 1
                    stops: const [0.0, 1.0],
                    colors: background,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                    left: 20.0, right: 20.0, top: devicePadding.top + 50.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    LoginCharacter(controller: _characterController),
                    Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.all(
                              Radius.circular(cornerRadius))),
                      child: Padding(
                        padding: const EdgeInsets.all(30.0),
                        child: Form(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              TrackingTextInput(
                                label: "Email",
                                hint: "What's your email address?",
                                onCaretMoved: (Offset caret) {
                                  _characterController.lookAt(caret);
                                },
                              ),
                              TrackingTextInput(
                                label: "Password",
                                hint: "Try 'bears'...",
                                isObscured: true,
                                onCaretMoved: (Offset caret) {
                                  _characterController.coverEyes(caret != null);
                                  _characterController.lookAt(null);
                                },
                                onTextChanged: (String value) {
                                  _password = value;
                                },
                              ),
                              SigninButton(
                                child: Text("Sign In",
                                    style: TextStyle(
                                        fontFamily: "RobotoMedium",
                                        fontSize: 16,
                                        color: Colors.white)),
                                onPressed: _login,
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> checkCredentials() async {
    return _password == "bears";
  }

  Future<void> _login() async {
    // Clear focus from text fields.
    FocusScope.of(context).requestFocus(FocusNode());
    // Bring hands down
    _characterController.coverEyes(false);

    // Check password
    bool valid = await checkCredentials();
    if (valid) {
      _characterController.rejoice();
    } else {
      _characterController.lament();
    }
  }
}
