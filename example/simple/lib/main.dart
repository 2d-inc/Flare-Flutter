import 'package:flutter/material.dart';
import 'package:flare_flutter/flare_actor.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {


  @override
  Widget build(BuildContext context) {
    var children = <Widget>[];

      children.add(SizedBox(
        width: 300,
        height: 300,
        child: FlareActor(
          'assets/bus.flr',
          animation: 'Untitled',
          snapToEnd: false,
        ),
      ));

    return Container(
      child: Column(
        children: children,
      ),
    );
  }
}