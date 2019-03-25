import 'package:flutter/material.dart';
import 'package:flare_flutter/flare_actor.dart';

class SmileySwitch extends StatelessWidget {
  final bool isOn;
  final VoidCallback onToggle;
  final bool snapToEnd;

  SmileySwitch(this.isOn, {this.snapToEnd, this.onToggle});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onToggle,
        child: Container(
            width: 200,
            height: 100,
            child: FlareActor("assets/Smiley Switch.flr",
			snapToEnd: snapToEnd,
                animation: isOn ? "On" : "Off")));
  }
}
