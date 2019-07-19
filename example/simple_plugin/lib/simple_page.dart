import 'package:flutter/material.dart';
import "package:flare_flutter/flare_actor.dart";

class SimplePage extends StatefulWidget {
  SimplePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _SimplePageState createState() => _SimplePageState();
}

class _SimplePageState extends State<SimplePage> {
  String _animationName = "idle";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: Text(widget.title)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                  child: FlareActor(
                "assets/Filip.flr",
                alignment: Alignment.center,
                fit: BoxFit.contain,
                animation: _animationName,
                package: 'simple_plugin',
              ))
            ],
          ),
        ));
  }
}
