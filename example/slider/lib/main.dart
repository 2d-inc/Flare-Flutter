import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:slider/house_controller.dart';
import 'package:slider/demo_button_bar.dart';
import 'package:slider/robot.dart';

void main() {
  SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom]);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new StackPage(title: 'Flutter Demo Home Page'),
    );
  }
}

class StackPage extends StatefulWidget {
  final String title;

  StackPage({this.title, Key key}) : super(key: key);

  @override
  _StackPageState createState() => _StackPageState();
}

class _StackPageState extends State<StackPage>
    with SingleTickerProviderStateMixin {
  static const List<String> _barOptions = ["DEMO 1", "DEMO 2"];

  Timer _currentDemoSchedule;
  HouseController _houseController;
  String _selectedDemo = _barOptions[0];
  double _offset = 0.0;

  Offset _touchPosition;

  AnimationController _sliderController;
  Animation<double> _slideAnimation;

  _demoValueChange(double rooms) {
    setState(() {
      _houseController.rooms = rooms.toInt();
    });
  }

  _touchUp(PointerUpEvent details) {
    _scheduleDemo();
  }

  _setTouchPosition(PointerEvent details) {
    setState(() {
      double dpr = window.devicePixelRatio;
      Offset position = details.position;
      _touchPosition = Offset(position.dx * dpr, position.dy * dpr);
    });
  }

  _scheduleDemo() {
    if (!_houseController.isDemoMode) {
      if (_currentDemoSchedule != null) {
        _currentDemoSchedule.cancel();
      }
      _currentDemoSchedule = Timer(const Duration(seconds: 2), () {
        setState(() {
          _houseController.isDemoMode = true;
        });
      });
    }
  }

  @override
  void initState() {
    _houseController = HouseController(demoValueChange: _demoValueChange);

    _sliderController =
        AnimationController(duration: const Duration(seconds: 2), vsync: this);
    _sliderController.addListener(() {
      setState(() {
        _offset = _slideAnimation.value;
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    // print(screenSize);
    return Scaffold(
        body: Container(
            color: Colors.black,
            child: Stack(fit: StackFit.expand, children: [
              Positioned(
                  left: (_offset - 1) * -screenSize.width,
                  width: screenSize.width,
                  height: screenSize.height,
                  child: Listener(
                    onPointerDown: _setTouchPosition,
                    onPointerMove: _setTouchPosition,
                    onPointerUp: (_) => _touchPosition = null,
                    child: NimaWidget(
                      "assets/nima/Robot_Kr2.nima",
                      scrollOffset: -_offset + 1,
                      touchPosition: _touchPosition,
                    ),
                  )),
              Positioned(
                left: _offset * -screenSize.width,
                width: screenSize.width,
                height: screenSize.height,
                child: Listener(
                    onPointerUp: _touchUp,
                    child: Stack(children: [
                      FlareActor(
                        "assets/flare/Resizing_House.flr",
                        fit: BoxFit.fill,
                        controller: _houseController,
                      ),
                      Container(
                          margin: const EdgeInsets.only(left: 40, right: 40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(_houseController.rooms.toString() + " ROOMS",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: "Roboto",
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                              Slider(
                                  value: _houseController.rooms.toDouble() - 3,
                                  min: 0.0,
                                  max: 3.0,
                                  divisions: 3,
                                  onChanged: (double value) {
                                    setState(() {
                                      _houseController.isDemoMode = false;
                                      _houseController.rooms =
                                          value.toInt() + 3;

                                      if (_currentDemoSchedule != null) {
                                        _currentDemoSchedule.cancel();
                                        _currentDemoSchedule = null;
                                      }
                                    });
                                  }),
                              Text(
                                  _houseController.isDemoMode
                                      ? "TAP TO TRY"
                                      : "DRAG TO CHANGE ROOMS",
                                  style: TextStyle(
                                      color: Colors.white.withAlpha(128),
                                      fontFamily: "Roboto",
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700))
                            ],
                          ))
                    ])),
              ),
              Positioned(
                  bottom: 46,
                  left: 40,
                  right: 40,
                  child: Container(
                      child: Column(children: [
                    Container(
                        margin: const EdgeInsets.only(right: 4),
                        width: 234,
                        height: 18,
                        decoration: BoxDecoration(
                            image: DecorationImage(
                                image: AssetImage("assets/images/2DLogo.png"),
                                fit: BoxFit.fitHeight,
                                alignment: Alignment.centerRight))),
                    Container(
                        margin: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                            "Powerful Realtime Animation for Apps, Games, and Web.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontFamily: "Roboto",
                                fontSize: 18.0,
                                decoration: TextDecoration.none,
                                fontWeight: FontWeight.w100))),
                    Container(
                        width: 200,
                        margin: const EdgeInsets.only(bottom: 40),
                        child: DemoButtonBar(_barOptions,
                            selectedItem: _selectedDemo,
                            selectedCallback: (int index, String demoLabel) {
                          _slideAnimation = Tween<double>(
                                  begin: _offset, end: index.toDouble())
                              .animate(_sliderController);
                          _sliderController
                            ..value = 0.0
                            ..fling(velocity: 0.5);

                          setState(() {
                            _selectedDemo = demoLabel;
                          });
                        })),
                    Row(children: [
                      Text("2DIMENSIONS.COM",
                          style: TextStyle(
                              color: Colors.white,
                              fontFamily: "Roboto",
                              fontSize: 14.0,
                              decoration: TextDecoration.none,
                              fontWeight: FontWeight.w700)),
                      Expanded(
                          child: Container(
                              margin: const EdgeInsets.only(right: 4.0),
                              child: Image.asset(
                                "assets/images/flutter.png",
                                width: 32,
                                height: 32,
                                alignment: Alignment.centerRight,
                              ))),
                      Text("FLUTTER",
                          style: TextStyle(
                              color: Colors.white,
                              fontFamily: "Roboto",
                              fontSize: 14.0,
                              decoration: TextDecoration.none,
                              fontWeight: FontWeight.w700))
                    ])
                  ])))
            ])));
  }
}
