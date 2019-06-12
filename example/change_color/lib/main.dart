import 'package:flare_flutter/flare_controller.dart';
import 'package:flare_flutter/flare.dart';
import 'package:flare_dart/math/mat2d.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

List<Color> exampleColors = <Color>[Colors.red, Colors.green, Colors.blue];

class _MyHomePageState extends State<MyHomePage> with FlareController {
  FlutterColorFill _fill;
  void initialize(FlutterActorArtboard artboard) {
    // Find our "Num 2" shape and get its fill so we can change it programmatically.
    FlutterActorShape shape = artboard.getNode("Num 2");
    _fill = shape?.fill as FlutterColorFill;
  }

  void setViewTransform(Mat2D viewTransform) {}

  bool advance(FlutterActorArtboard artboard, double elapsed) {
    // advance is called whenever the flare artboard is about to update (before it draws).
    Color nextColor = exampleColors[_counter % exampleColors.length];
    if (_fill != null) {
      _fill.uiColor = nextColor;
    }
    // Return false as we don't need to be called again. You'd return true if you wanted to manually animate some property.
    return false;
  }

  // We're going to use the counter to iterate the color.
  int _counter = 0;
  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
	  // advance the controller
	  isActive.value = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: FlareActor("assets/Change Color Example.flr", // You can find the example project here: https://www.2dimensions.com/a/castor/files/flare/change-color-example
          fit: BoxFit.contain, alignment: Alignment.center, controller: this),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
