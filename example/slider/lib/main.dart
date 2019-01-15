import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:slider/house_controller.dart';

import 'demo_button_bar.dart';
import 'house.dart';
import 'robot.dart';

void main() {
  SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom]);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new StackPage(title: 'Flutter Demo Home Page'),
    );
  }
}

class StackPage extends StatefulWidget
{
    final String title;

    StackPage({this.title, Key key}) : super(key: key);

    @override
    _StackPageState createState() => _StackPageState();
}

class _StackPageState extends State<StackPage> with SingleTickerProviderStateMixin
{
    static const List<String> _barOptions = ["DEMO 1", "DEMO 2"];
    
    Timer _currentDemoSchedule;
    HouseController _houseController;
    String _selectedDemo = _barOptions[0];
    double _offset = 0.0;

    AnimationController _sliderController;
    Animation<double> _slideAnimation;

    _demoValueChange(double rooms)
    {
        setState(() {
           _houseController.rooms = rooms.toInt();
        });
    }

    _touchUp(PointerUpEvent details)
    {
        _scheduleDemo();
    }

    _scheduleDemo()
    {
        if(!_houseController.isDemoMode)
        {
            if(_currentDemoSchedule != null)
            {
                _currentDemoSchedule.cancel();
            }
            _currentDemoSchedule = Timer(const Duration(seconds: 2), (){
                setState(() {
                    _houseController.isDemoMode = true;
                });
            });
        }
        
    }

    @override
    void initState() {
        _houseController = HouseController(demoValueChange: _demoValueChange);

        _sliderController = AnimationController(duration: const Duration(seconds: 2), vsync: this);
        _sliderController.addListener(()
        {
            setState(() {
                _offset = _slideAnimation.value;
            });
        });

        super.initState();
      }

    @override
    Widget build(BuildContext context)
    {
        Size screenSize = MediaQuery.of(context).size;
        // print(s);
        return Scaffold(
            body: Container(
                color: Colors.black,
                child: Stack(
                    fit: StackFit.expand,
                    children:
                    [
                        Positioned(
                            left: _offset*-screenSize.width,
                            width: screenSize.width,
                            height: screenSize.height,
                          child: Listener(
                              onPointerUp: _touchUp,
                              child: Stack(
                                  children:
                                  [
                                      FlareActor(
                                          "assets/Resizing_House.flr",
                                          fit: BoxFit.fill,
                                          controller: _houseController,
                                      ),
                                      Container(
                                          margin: const EdgeInsets.only(left: 40, right:40),
                                          child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children:
                                              [
                                                  Text(
                                                      _houseController.rooms.toString() + " ROOMS",
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontFamily: "Roboto",
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w700
                                                      )
                                                  ),
                                                  Slider(
                                                      value: _houseController.rooms.toDouble()-3,
                                                      min: 0.0,
                                                      max: 3.0,
                                                      divisions: 3,
                                                      onChanged: (double value)
                                                      {
                                                          setState(() {
                                                              _houseController.isDemoMode = false;
                                                              _houseController.rooms = value.toInt() + 3;
                                                              
                                                              if(_currentDemoSchedule != null)
                                                              {
                                                                  _currentDemoSchedule.cancel();
                                                                  _currentDemoSchedule = null;
                                                              }
                                                          });
                                                      }
                                                  ),
                                                  Text(
                                                      _houseController.isDemoMode ? 
                                                          "TAP TO TRY" : "DRAG TO CHANGE ROOMS",
                                                      style: TextStyle(
                                                          color: Colors.white.withAlpha(128),
                                                          fontFamily: "Roboto",
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w700
                                                      )
                                                  )
                                            ],
                                          )
                                      )
                                  ]
                              )
                          ),
                        ),
                        Container(
                            margin: const EdgeInsets.only(bottom:46, left:40, right:40),
                            // color: Colors.black45,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children:
                                [
                                    Container(
                                        margin: const EdgeInsets.only(bottom: 40),
                                        // color: Colors.white54,
                                        child: DemoButtonBar(
                                            _barOptions,
                                            selectedItem: _selectedDemo,
                                            selectedCallback: (int index, String demoLabel)
                                            {
                                                _slideAnimation = Tween<double>(
                                                    begin: _offset,
                                                    end: index.toDouble()
                                                ).animate(_sliderController);

                                                _sliderController
                                                    ..value = 0.0
                                                    ..fling(velocity: 0.5);
                                                setState((){
                                                    _selectedDemo = demoLabel;
                                                });
                                            }
                                        )
                                    )
                                ]
                            ),
                        )
                    ]
                )
            ) 
        );
    }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  double _sliderValue = 3.0;
  bool _isDemoMode = true;
  Timer _currentDemoSchedule;
  Object _selectedDemo = "DEMO 1";
  double _offset = 0.0;
  Offset _touchPosition;
  bool _doubleTap = false;
  int _lastTouch = 0;

  AnimationController _controller;
  Animation<double> _slideAnimation;

  _MyHomePageState() {
    _controller = new AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);
    _controller.addListener(() {
      setState(() {
        _offset = _slideAnimation.value;
      });
    });
  }

  void _scheduleDemo() {
    if (_isDemoMode) {
      return;
    }
    if (_currentDemoSchedule != null) {
      _currentDemoSchedule.cancel();
    }
    _currentDemoSchedule = new Timer(const Duration(seconds: 5), () {
      setState(() {
        _isDemoMode = true;
      });
    });
  }

  void _demoValueChange(double rooms) {
    setState(() {
      _sliderValue = rooms - 3;
    });
  }

  void _releaseScreen(PointerUpEvent details) {
    _scheduleDemo();
    setState(() {
      _touchPosition = null;
      _doubleTap = false;
    });
  }

  void _touchScreen(PointerDownEvent details) {
    setState(() {
      int now = new DateTime.now().millisecondsSinceEpoch;
      int diff = now - _lastTouch;
      _touchPosition = new Offset(details.position.dx * window.devicePixelRatio,
          details.position.dy * window.devicePixelRatio);
      _doubleTap = diff < 500;
      _lastTouch = now;
    });
    if (_currentDemoSchedule != null) {
      _currentDemoSchedule.cancel();
      _currentDemoSchedule = null;
    }
    _isDemoMode = false;
  }

  void _pointerMove(PointerMoveEvent details) {
    setState(() {
      _doubleTap = false;
      _touchPosition = new Offset(details.position.dx * window.devicePixelRatio,
          details.position.dy * window.devicePixelRatio);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
            color: Colors.black,
            child: Stack(fit: StackFit.expand, children: <Widget>[
              NimaWidget("assets/nima/Robot_Kr2",
                  scrollOffset: -_offset + 1.0, touchPosition: _touchPosition),
              Listener(
                  onPointerUp: _releaseScreen,
                  onPointerMove: _pointerMove,
                  onPointerDown: _touchScreen,
                  child: Stack(children: <Widget>[
                    FlareHouse(
                        // flare: "assets/flares/HouseSky",
                        flare: "assets/flares/Resizing_House.flr",
                        rooms: (_sliderValue + 3).round(),
                        isDemoMode: _isDemoMode,
                        demoValueChange: _demoValueChange,
                        offset: -_offset),
                    OffsetStack(offset: -_offset, children: <Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text((_sliderValue + 3).round().toString() + " ROOMS",
                              style: TextStyle(
                                  color: Color.fromARGB(255, 242, 242, 242),
                                  fontFamily: "Roboto",
                                  fontSize: 14.0,
                                  decoration: TextDecoration.none,
                                  fontWeight: FontWeight.w700)),
                          Container(
                            margin: EdgeInsets.only(
                                top: 0.0, bottom: 0.0, left: 40.0, right: 40.0),
                            child: Slider(
                              value: _sliderValue,
                              min: 0.0,
                              max: 3.0,
                              divisions: 3,
                              onChanged: (double value) {
                                setState(() {
                                  _isDemoMode = false;
                                  _sliderValue = value;

                                  if (_currentDemoSchedule != null) {
                                    _currentDemoSchedule.cancel();
                                    _currentDemoSchedule = null;
                                  }
                                });
                              },
                            ),
                          ),
                          Text(
                              _isDemoMode
                                  ? "TAP TO TRY"
                                  : "DRAG TO CHANGE ROOMS",
                              style: TextStyle(
                                  color: Color.fromARGB(128, 255, 255, 255),
                                  fontFamily: "Roboto",
                                  fontSize: 14.0,
                                  decoration: TextDecoration.none,
                                  fontWeight: FontWeight.w700)),
                        ],
                      )
                    ])
                  ])),
              Container(
                  margin: EdgeInsets.only(
                      top: 0.0, bottom: 46.0, left: 40.0, right: 40.0),
                  //color:Colors.black,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Container(
                          margin: const EdgeInsets.only(right: 4.0),
                          width: 234.0,
                          height: 18.0,
                          decoration: BoxDecoration(
                              image: DecorationImage(
                                  image: AssetImage("assets/images/2DLogo.png"),
                                  fit: BoxFit.fitHeight,
                                  alignment: Alignment.centerRight))),
                      Container(
                        margin: const EdgeInsets.only(top: 20.0, bottom: 20.0),
                        child: Text(
                            "Powerful Realtime Animation for Apps, Games, and Web.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Color.fromARGB(255, 255, 255, 255),
                                fontFamily: "Roboto",
                                fontSize: 18.0,
                                decoration: TextDecoration.none,
                                fontWeight: FontWeight.w100)),
                      ),
                      Container(
                        margin: const EdgeInsets.only(bottom: 40.0),
                        child: DemoButtonBar(["DEMO 1", "DEMO 2"],
                            selectedItem: _selectedDemo,
                            selectedCallback: (int index, Object item) {
                          _slideAnimation = Tween<double>(
                                  begin: _offset, end: index.toDouble())
                              .animate(_controller);

                          _controller
                            ..value = 0.0
                            ..fling(velocity: 0.5);

                          setState(() {
                            _selectedDemo = item;
                          });
                        }),
                      ),
                      Row(children: <Widget>[
                        Text("2DIMENSIONS.COM",
                            style: TextStyle(
                                color: Color.fromARGB(255, 255, 255, 255),
                                fontFamily: "Roboto",
                                fontSize: 14.0,
                                decoration: TextDecoration.none,
                                fontWeight: FontWeight.w700)),
                        Expanded(
                            child: Container(
                                margin: const EdgeInsets.only(right: 4.0),
                                width: 32.0,
                                height: 32.0,
                                decoration: BoxDecoration(
                                    image: DecorationImage(
                                        image: AssetImage(
                                            "assets/images/flutter.png"),
                                        fit: BoxFit.fitHeight,
                                        alignment: Alignment.centerRight)))),
                        Text("FLUTTER",
                            style: TextStyle(
                                color: Color.fromARGB(255, 255, 255, 255),
                                fontFamily: "Roboto",
                                fontSize: 14.0,
                                decoration: TextDecoration.none,
                                fontWeight: FontWeight.w700))
                      ])
                    ],
                  ))
            ])));
  }
}

class OffsetStack extends MultiChildRenderObjectWidget {
  final double offset;
  OffsetStack({
    Key key,
    this.offset,
    List<Widget> children: const <Widget>[],
  }) : super(key: key, children: children);

  @override
  RenderOffsetStack createRenderObject(BuildContext context) {
    return new RenderOffsetStack(offset);
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderOffsetStack renderObject) {
    renderObject.offset = offset;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
  }
}

class RenderOffsetStackParentData extends ContainerBoxParentData<RenderBox> {}

class RenderOffsetStack extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, RenderOffsetStackParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox,
            RenderOffsetStackParentData> {
  double _offset = 0.0;

  RenderOffsetStack(double _offset) {
    this.offset = offset;
  }

  double get offset {
    return _offset;
  }

  set offset(double v) {
    if (_offset == v) {
      return;
    }
    _offset = v;

    markNeedsLayout();
  }

  @override
  bool get sizedByParent => true;

  @override
  void performResize() {
    size = constraints.biggest;
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! RenderOffsetStackParentData) {
      child.parentData = new RenderOffsetStackParentData();
    }
  }

  @override
  void performLayout() {
    // For now, just place them in a grid. Later we need to use MaxRects to figure out the best layout as some cells will be double height.
    RenderBox child = firstChild;

    int idx = 0;
    while (child != null) {
      Constraints constraints = new BoxConstraints(
          minWidth: size.width,
          maxWidth: size.width,
          minHeight: size.height,
          maxHeight: size.height);
      child.layout(constraints, parentUsesSize: true);
      final RenderOffsetStackParentData childParentData = child.parentData;
      childParentData.offset = new Offset(_offset * size.width, 0.0);
      child = childParentData.nextSibling;
      idx++;
    }
  }

  @override
  bool hitTestChildren(HitTestResult result, {Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }
}
