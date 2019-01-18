import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:slider/house_controller.dart';

class Page extends StatefulWidget {
  final String title;

  Page({this.title, Key key}) : super(key: key);

  @override
  _PageState createState() => _PageState();
}

class _PageState extends State<Page> with SingleTickerProviderStateMixin {
  /// Inactivity [Timer]: if it fires, set the animation state back to "Demo Mode".
  Timer _currentDemoSchedule;
  HouseController _houseController;

  @override
  void initState() {
    _houseController = HouseController(demoUpdated: _update);
    super.initState();
  }

  /// Trigger an update.
  _update() => setState((){});

  _scheduleDemo(PointerUpEvent details) {
    if (!_houseController.isDemoMode) {
      if (_currentDemoSchedule != null) {
        _currentDemoSchedule.cancel();
      }
      _currentDemoSchedule = Timer(const Duration(seconds: 2), () {
        setState(() {
          /// Restart the demo at the end of this timer.
          _houseController.isDemoMode = true;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
            child: Listener(
              onPointerUp: _scheduleDemo,
              child: Stack(fit: StackFit.expand, children: [
                FlareActor("assets/Resizing_House.flr",
                  controller: _houseController,
                  fit: BoxFit.cover,
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
                            min: 0,
                            max: 3,
                            divisions: 3,
                            /// Get the room value and adjust it for the slider's min/max value.
                            value: _houseController.rooms.toDouble() - 3,
                            onChanged: (double value) {
                              /// [setState()] triggers a visual refresh with the updated parameters.
                              setState(() {
                                /// Stop the demo.
                                _houseController.isDemoMode = false;
                                /// When the value of the slider changes, the rooms setter
                                /// is invoked, which enqueues the new animation.
                                _houseController.rooms = value.toInt() + 3;

                                /// Stop a scheduled timer, if any.
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
