import "package:flare/flare_actor.dart";
import "package:flutter/material.dart";

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'JSON Reader Demo',
      theme: new ThemeData(primarySwatch: Colors.blue),
      home: new MyHomePage(title: 'Flare-Flutter with JSON'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _animationName = "Triangling";

  @override
    Widget build(BuildContext context) {
        return new Scaffold(
            backgroundColor: Colors.grey,
            appBar: new AppBar(title: new Text(widget.title)),
            body: new Center(
                child: new Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: 
                    [
                        Expanded(
                            child: FlareActor("assets/ball.flj",
                                alignment: Alignment.center,
                                fit: BoxFit.none,
                                animation: _animationName,
                            )
                        )
                    ],
                ),
            )
        );
    }
}