import 'dart:math';
import 'dart:ui';

import 'package:flare_flutter/flare.dart';
import 'package:flare_flutter/flare/math/mat2d.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flare_flutter/flare_controller.dart';
import 'package:flutter/animation.dart';

typedef void OnUpdated();

class HouseController extends FlareController {
  static const double DemoMixSpeed = 10;
  static const double FPS = 60;

  final OnUpdated demoUpdated;

  HouseController({this.demoUpdated});

  bool isDemoMode = true;
  int _rooms = 6;
  double _lastDemoValue = 0.0;
  FlutterActorArtboard _artboard;
  FlareAnimationLayer _demoAnimation;
  FlareAnimationLayer _skyAnimation;

  final List<FlareAnimationLayer> _roomAnimations = [];

  @override
  bool advance(FlutterActorArtboard artboard, double elapsed) {
    int len = _roomAnimations.length - 1;
    for (int i = len; i >= 0; i--) {
      FlareAnimationLayer layer = _roomAnimations[i];
      layer.time += elapsed;
      layer.mix = min(1.0, layer.time / 0.07);
      layer.apply(artboard);
      if (layer.isDone) {
        _roomAnimations.removeAt(i);
      }
    }

    double demoMix =
        _demoAnimation.mix + DemoMixSpeed * (isDemoMode ? elapsed : -elapsed);
    demoMix = demoMix.clamp(0.0, 1.0);
    _demoAnimation.mix = demoMix;
    if (demoMix != 0.0) {
      _demoAnimation.time =
          (_demoAnimation.time + elapsed) % _demoAnimation.duration;
      _demoAnimation.apply(artboard);
      _checkRoom();
    }

    _skyAnimation.time =
        (_skyAnimation.time + elapsed) % _skyAnimation.duration;
    _skyAnimation.apply(artboard);
    return true;
  }

  @override
  void initialize(FlutterActorArtboard artboard) {
    _artboard = artboard;
    _demoAnimation = FlareAnimationLayer()
      ..animation = _artboard.getAnimation("Demo Mode");
    _skyAnimation = FlareAnimationLayer()
      ..animation = _artboard.getAnimation("Sun Rotate")
      ..mix = 1.0;
    ActorAnimation endAnimation = artboard.getAnimation("to 6");
    if (endAnimation != null) {
      endAnimation.apply(endAnimation.duration, artboard, 1.0);
    }
  }

  @override
  void setViewTransform(Mat2D viewTransform) {}

  _checkRoom() {
    double demoFrame = _demoAnimation.time * FPS;
    double demoValue = 0.0;
    if (demoFrame <= 15) {
      demoValue =
          lerpDouble(6.0, 5.0, Curves.easeInOut.transform(demoFrame / 15));
    } else if (demoFrame <= 36) {
      demoValue = 5.0;
    } else if (demoFrame <= 50) {
      demoValue = lerpDouble(
          5.0, 4.0, Curves.easeInOut.transform((demoFrame - 36) / (50 - 36)));
    } else if (demoFrame <= 72) {
      demoValue = 4.0;
    } else if (demoFrame <= 87) {
      demoValue = lerpDouble(
          4.0, 3.0, Curves.easeInOut.transform((demoFrame - 72) / (87 - 72)));
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
      this.rooms = demoValue.toInt();
      if (demoUpdated != null) {
        demoUpdated();
      }
    }
  }

  _enqueueAnimation(String name) {
    ActorAnimation animation = _artboard.getAnimation(name);
    if (animation != null) {
      _roomAnimations.add(FlareAnimationLayer()..animation = animation);
    }
  }

  set rooms(int value) {
    if (_rooms == value) {
      return;
    }

    if (_artboard != null) {
      _enqueueAnimation("to $value");

      if ((_rooms > 4 && value < 5) || (_rooms < 5 && value > 4)) {
        _enqueueAnimation("Center Window Highlight");
      }
      if (_rooms == 3 || value == 3) {
        _enqueueAnimation("Outer Windows Highlight");
      }
      if (value == 6 || _rooms == 6) {
        _enqueueAnimation("Inner Windows Highlight");
      }
    }
    _rooms = value;
  }

  int get rooms => _rooms;
}
