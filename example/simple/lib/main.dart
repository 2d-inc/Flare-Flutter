import 'package:flare_flutter/flare_actor.dart';
import 'package:flare_flutter/flare_cache_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flare_flutter/provider/asset_flare.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flare Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MyHomePage(title: 'Flare-Flutter'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({
    required this.title,
    Key? key,
  }) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _useAA = true;
  String _animationName = 'idle';
  final asset = AssetFlare(bundle: rootBundle, name: 'assets/Filip.flr');

  /// Toggle antialiasing on [FlareActor]
  void _toggleAntialiasing() {
    setState(() {
      _useAA = !_useAA;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: FlareCacheBuilder(
                [asset],
                builder: (BuildContext context, bool isWarm) {
                  return !isWarm
                      ? Container(child: Text('NO'))
                      : FlareActor.asset(
                          asset,
                          alignment: Alignment.center,
                          fit: BoxFit.contain,
                          animation: _animationName,
                          antialias: _useAA,
                        );
                },
              ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: _toggleAntialiasing,
          child: Icon(
              _useAA ? Icons.center_focus_strong : Icons.center_focus_weak)),
    );
  }
}
