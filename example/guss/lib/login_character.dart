import 'package:flare_flutter/flare_actor.dart';
import 'package:flare_flutter/flare_controller.dart';
import 'package:flutter/material.dart';

class LoginCharacter extends StatelessWidget {
  final FlareController controller;

  const LoginCharacter({Key key, this.controller}) : super(key: key);

  static double projectGaze = 200;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.only(left: 30.0, right: 30.0),
      child: FlareActor(
        "assets/Guss.flr",
        shouldClip: false,
        alignment: Alignment.topCenter,
        fit: BoxFit.cover,
        controller: controller,
      ),
    );
  }
}
