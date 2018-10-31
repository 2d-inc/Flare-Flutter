import "package:flare/flare.dart";
import "dart:ui" as ui;
import "dart:typed_data";

FlutterActor actor;
//ActorAnimation animation;

double lastFrameTime = 0.0;

void beginFrame(Duration timeStamp) 
{
	final double t = timeStamp.inMicroseconds / Duration.microsecondsPerMillisecond / 1000.0;
	double elapsed = t - lastFrameTime;
	lastFrameTime = t;
	if(lastFrameTime == 0)
	{
		// hack to circumvent not being enable to initialize lastFrameTime to a starting timeStamp (maybe it's just the date?)
		// Is the FrameCallback supposed to pass elapsed time since last frame? timeStamp seems to behave more like a date
		ui.window.scheduleFrame();
		return;
	}
	
	actor.advance(elapsed);

	// Harcoding animation time as updating the nima file seemed to still use the previously cached one. Or I copied the wrong file with the old 10 seconds in it :)
	//double duration = 13.0/24.0;
	//animation.apply(t%duration/*animation.duration*/, actor, 1.0);

	final ui.Rect paintBounds = ui.Offset.zero & (ui.window.physicalSize / ui.window.devicePixelRatio);
	final ui.PictureRecorder recorder = new ui.PictureRecorder();
	final ui.Canvas canvas = new ui.Canvas(recorder, paintBounds);

	// "clearing" the screen with a background color
	canvas.drawRect(new ui.Rect.fromLTRB(0.0, 0.0, ui.window.physicalSize.width, ui.window.physicalSize.height),
					new ui.Paint()..color = new ui.Color.fromARGB(255, 125, 152, 165));
					
	canvas.translate(paintBounds.width / 2.0, paintBounds.height / 2.0);

	// Nima coordinates are:
	//         1
	//         |
	//         |
	// -1 ------------ 1
	//         |
	//         |
	//        -1
	canvas.scale(0.35, 0.35);

	actor.draw(canvas);

	final ui.Picture picture = recorder.endRecording();

	// COMPOSITE

	final double devicePixelRatio = ui.window.devicePixelRatio;
	final Float64List deviceTransform = new Float64List(16)
		..[0] = devicePixelRatio
		..[5] = devicePixelRatio
		..[10] = 1.0
		..[15] = 1.0;
		
	final ui.SceneBuilder sceneBuilder = new ui.SceneBuilder()
		..pushTransform(deviceTransform)
		..addPicture(ui.Offset.zero, picture)
		..pop();
	ui.window.render(sceneBuilder.build());

	// After rendering the current frame of the animation, we ask the engine to
	// schedule another frame. The engine will call beginFrame again when its time
	// to produce the next frame.
	ui.window.scheduleFrame();
}

void main() 
{
	actor = new FlutterActor();
	actor.loadFromBundle("assets/ball.flj").then(
		(bool success)
		{
			print("HERE?");
			//animation = actor.getAnimation("Run");
			ui.window.onBeginFrame = beginFrame;
			ui.window.scheduleFrame();
		}
	);
}

/*import 'package:flutter/material.dart';
import "package:flare/flare.dart";

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget 
{
	MyApp() : super()
	{
		print("hi");
		FlutterActor actor = new FlutterActor();
		actor.loadFromBundle("assets/Dots").then(
			(bool success)
			{
				print("LOAD?");
				//animation = actor.getAnimation("Run");
				//ui.window.onBeginFrame = beginFrame;
				//ui.window.scheduleFrame();
			}
		);
	}
	// This widget is the root of your application.
	@override
	Widget build(BuildContext context) {
	return new MaterialApp(
		title: 'Flutter Demo',
		theme: new ThemeData(
		// This is the theme of your application.
		//
		// Try running your application with "flutter run". You'll see the
		// application has a blue toolbar. Then, without quitting the app, try
		// changing the primarySwatch below to Colors.green and then invoke
		// "hot reload" (press "r" in the console where you ran "flutter run",
		// or press Run > Flutter Hot Reload in IntelliJ). Notice that the
		// counter didn't reset back to zero; the application is not restarted.
		primarySwatch: Colors.blue,
		),
		home: new MyHomePage(title: 'Flutter Demo Home Page'),
	);
	}
}

class MyHomePage extends StatefulWidget {
	MyHomePage({Key key, this.title}) : super(key: key);

	// This widget is the home page of your application. It is stateful, meaning
	// that it has a State object (defined below) that contains fields that affect
	// how it looks.

	// This class is the configuration for the state. It holds the values (in this
	// case the title) provided by the parent (in this case the App widget) and
	// used by the build method of the State. Fields in a Widget subclass are
	// always marked "final".

	final String title;

	@override
	_MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
	int _counter = 0;

	void _incrementCounter() {
	setState(() {
		// This call to setState tells the Flutter framework that something has
		// changed in this State, which causes it to rerun the build method below
		// so that the display can reflect the updated values. If we changed
		// _counter without calling setState(), then the build method would not be
		// called again, and so nothing would appear to happen.
		_counter++;
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
	return new Scaffold(
		appBar: new AppBar(
		// Here we take the value from the MyHomePage object that was created by
		// the App.build method, and use it to set our appbar title.
		title: new Text(widget.title),
		),
		body: new Center(
		// Center is a layout widget. It takes a single child and positions it
		// in the middle of the parent.
		child: new Column(
			// Column is also layout widget. It takes a list of children and
			// arranges them vertically. By default, it sizes itself to fit its
			// children horizontally, and tries to be as tall as its parent.
			//
			// Invoke "debug paint" (press "p" in the console where you ran
			// "flutter run", or select "Toggle Debug Paint" from the Flutter tool
			// window in IntelliJ) to see the wireframe for each widget.
			//
			// Column has various properties to control how it sizes itself and
			// how it positions its children. Here we use mainAxisAlignment to
			// center the children vertically; the main axis here is the vertical
			// axis because Columns are vertical (the cross axis would be
			// horizontal).
			mainAxisAlignment: MainAxisAlignment.center,
			children: <Widget>[
			new Text(
				'You have pushed the button this many times:',
			),
			new Text(
				'$_counter',
				style: Theme.of(context).textTheme.display1,
			),
			],
		),
		),
		floatingActionButton: new FloatingActionButton(
		onPressed: _incrementCounter,
		tooltip: 'Increment',
		child: new Icon(Icons.add),
		), // This trailing comma makes auto-formatting nicer for build methods.
	);
	}
}
*/