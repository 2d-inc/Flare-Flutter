import 'package:flutter/material.dart' hide Page;
import 'package:flutter/services.dart';
import 'package:slider/page.dart';

void main() {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.bottom]);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Slider Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Page(title: 'Flutter Slider Page'),
    );
  }
}