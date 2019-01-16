import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:slider/house_controller.dart';

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
  Timer _currentDemoSchedule;
  HouseController _houseController;

  _demoValueChange(double rooms) {
    setState(() {
      _houseController.rooms = rooms.toInt();
    });
  }

  _touchUp(PointerUpEvent details) {
    _scheduleDemo();
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
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
            color: Colors.black,
            child: Listener(
              onPointerUp: _touchUp,
              child: Stack(fit: StackFit.expand, children: [
                FlareActor(
                  "assets/Resizing_House.flr",
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
                                _houseController.rooms = value.toInt() + 3;

                                if (_currentDemoSchedule != null) {
                                  _currentDemoSchedule.cancel();
                                  _currentDemoSchedule = null;
                                }
                              });
                            }),
                        Text("DRAG TO CHANGE ROOMS",
                            style: TextStyle(
                                color: Colors.white.withAlpha(228),
                                fontFamily: "Roboto",
                                fontSize: 14,
                                fontWeight: FontWeight.w700))
                      ],
                    ))
              ]),
            )));
  }
}
