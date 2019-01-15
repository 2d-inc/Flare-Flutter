import 'dart:math';
import 'dart:ui';

import 'package:flare_flutter/flare.dart' as flr;
import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

typedef void ValueChangeCallback(double value);

class FlareHouse extends LeafRenderObjectWidget {
  final String flare;
  final int rooms;
  final bool isDemoMode;
  final ValueChangeCallback demoValueChange;
  final double offset;
  FlareHouse(
      {Key key,
      this.flare,
      this.isDemoMode,
      this.demoValueChange,
      this.rooms,
      this.offset})
      : super(key: key);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return new FlareHouseRenderObject(
        rooms: rooms,
        flare: flare,
        demoValueChange: demoValueChange,
        isDemoMode: isDemoMode,
        offset: offset);
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant FlareHouseRenderObject renderObject) {
    renderObject
      ..rooms = rooms
      ..flare = flare
      ..demoValueChange = demoValueChange
      ..isDemoMode = isDemoMode
      ..offset = offset;
  }
}

class AnimationState {
  flr.ActorAnimation animation;
  double time;
}

class FlareHouseRenderObject extends RenderBox {
  int _rooms;
  bool _isDemoMode = false;
  String _flare;
  Rect _flareRect = Rect.zero;
  flr.FlutterActorArtboard _artboard;
  flr.ActorAnimation _demoAnimation;
  flr.ActorAnimation _skyAnimation;
  double _skyAnimationTime;
  double _demoTime;
  double _demoMix;
  double _lastDemoValue;
  double _offset;
  ValueChangeCallback demoValueChange;
  List<AnimationState> _animationStack = new List<AnimationState>();

  double _lastFrameTime = 0.0;
  bool _isPlaying = false;

  set isPlaying(bool play) {
    if (_isPlaying == play) {
      return;
    }
    _isPlaying = play;
    if (play) {
      _lastFrameTime = new DateTime.now().microsecondsSinceEpoch /
          Duration.microsecondsPerMillisecond /
          1000.0;
      SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
    }
  }

  void beginFrame(Duration timeStamp) {
    final double t = new DateTime.now().microsecondsSinceEpoch /
        Duration.microsecondsPerMillisecond /
        1000.0;

    double elapsed = t - _lastFrameTime;
    _lastFrameTime = t;

    if (_artboard != null) {
      for (int i = 0; i < _animationStack.length; i++) {
        AnimationState state = _animationStack[i];
        state.time += elapsed;
        double mix = min(1.0, state.time / 0.07);
        state.animation.apply(state.time, _artboard, mix);
        if (state.time >= state.animation.duration) {
          _animationStack.removeAt(i);
          i--;
        }
      }

      const DemoMixSpeed = 10.0;
      _demoMix += DemoMixSpeed * (isDemoMode ? elapsed : -elapsed);
      _demoMix = _demoMix.clamp(0.0, 1.0);
      if (_demoMix != 0.0) {
        _demoTime = (_demoTime + elapsed) % _demoAnimation.duration;
        _demoAnimation.apply(_demoTime, _artboard, _demoMix);

        // Update value change callback.
        double demoFrame = _demoTime * 60.0;

        double demoValue = 0.0;
        if (demoFrame <= 15) {
          demoValue =
              lerpDouble(6.0, 5.0, Curves.easeInOut.transform(demoFrame / 15));
        } else if (demoFrame <= 36) {
          demoValue = 5.0;
        } else if (demoFrame <= 50) {
          demoValue = lerpDouble(5.0, 4.0,
              Curves.easeInOut.transform((demoFrame - 36) / (50 - 36)));
        } else if (demoFrame <= 72) {
          demoValue = 4.0;
        } else if (demoFrame <= 87) {
          demoValue = lerpDouble(4.0, 3.0,
              Curves.easeInOut.transform((demoFrame - 72) / (87 - 72)));
        } else if (demoFrame <= 128) {
          demoValue = 3.0;
        } else if (demoFrame <= 142) {
          demoValue = lerpDouble(3.0, 6.0,
              Curves.easeInOut.transform((demoFrame - 128) / (142 - 128)));
        } else if (demoFrame <= 164) {
          demoValue = 6.0;
        }

        if (_lastDemoValue != demoValue) {
          _lastDemoValue = demoValue;
          if (demoValueChange != null) {
            demoValueChange(demoValue);
          }
        }
      }

      if (_skyAnimation != null) {
        _skyAnimationTime += elapsed;
        _skyAnimation.apply(
            _skyAnimationTime % _skyAnimation.duration, _artboard, 1.0);
      }
      _artboard.advance(elapsed);
    }

    markNeedsPaint();
    if (_isPlaying) {
      SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
    }
  }

  FlareHouseRenderObject(
      {int rooms,
      bool isDemoMode,
      String flare,
      double offset,
      this.demoValueChange}) {
    this.flare = flare;
    this.rooms = rooms;
    this.isDemoMode = isDemoMode;
    this.offset = offset;
  }

  @override
  bool get sizedByParent => true;

  @override
  bool hitTestSelf(Offset screenOffset) => true;

  @override
  void performResize() {
    size = constraints.biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final Canvas canvas = context.canvas;
    if (_offset <= -1.0) {
      return;
    }
    if (_artboard != null) {
      canvas.save();
      canvas.translate(size.width * _offset, 0.0);
      canvas.clipRect(offset & size);

      double scale =
          max(size.width / _flareRect.width, size.height / _flareRect.height);
      canvas.translate(
          offset.dx +
              size.width / 2.0 -
              _flareRect.left * scale -
              _flareRect.width * scale / 2.0,
          offset.dy +
              size.height / 2.0 -
              _flareRect.top * scale -
              _flareRect.height * scale / 2.0);
      canvas.scale(scale, scale);

      _artboard.draw(canvas);
      canvas.restore();
    }
  }

  bool get isDemoMode {
    return _isDemoMode;
  }

  set isDemoMode(bool value) {
    if (_isDemoMode == value) {
      return;
    }
    _isDemoMode = value;
    _demoTime = 0.0;
  }

  String get flare {
    return _flare;
  }

  set flare(String value) {
    if (_flare == value) {
      return;
    }
    _flare = value;

    if (value == null) {
      markNeedsPaint();
      return;
    }
    flr.FlutterActor actor = new flr.FlutterActor();
    actor.loadFromBundle(value).then((bool success) {
      _artboard = actor?.artboard;
      if (_artboard != null) {
        _artboard.advance(0.0);
      }
      flr.ActorNode bottomRightNode = _artboard.getNode("BottomRight");
      _flareRect =
          new Rect.fromLTRB(0.0, 0.0, bottomRightNode.x, bottomRightNode.y);

      _demoAnimation = _artboard.getAnimation("Demo Mode");
      _demoTime = 0.0;
      _demoMix = 0.0;

      _skyAnimation = _artboard.getAnimation("Sun Rotate");
      _skyAnimationTime = 0.0;
      flr.ActorAnimation animation = _artboard.getAnimation("to 6");
      animation?.apply(animation.duration, _artboard, 1.0);
      isPlaying = true;
      markNeedsPaint();
    });
  }

  void queueAnimation(String name) {
    if (_artboard != null) {
      flr.ActorAnimation animation = _artboard.getAnimation(name);
      if (animation != null) {
        _animationStack.add(new AnimationState()
          ..animation = animation
          ..time = 0.0);
      }
    }
  }

  int get rooms {
    return _rooms;
  }

  set rooms(int value) {
    if (_rooms == value) {
      return;
    }
    if (_artboard != null) {
      queueAnimation("to $value");
      flr.ActorAnimation animation = _artboard.getAnimation("to $value");
      if (animation != null) {
        _animationStack.add(new AnimationState()
          ..animation = animation
          ..time = 0.0);
      }

      if ((rooms > 4 && value < 5) || (rooms < 5 && value > 4)) {
        queueAnimation("Center Window Highlight");
      }
      if (rooms == 3 || value == 3) {
        queueAnimation("Outer Windows Highlight");
      }
      if (value == 6 || rooms == 6) {
        queueAnimation("Inner Windows Highlight");
      }
    }
    _rooms = value;
    markNeedsPaint();
  }

  double get offset {
    return _offset;
  }

  set offset(double v) {
    if (_offset == v) {
      return;
    }
    _offset = v;
    markNeedsPaint();
  }
}
