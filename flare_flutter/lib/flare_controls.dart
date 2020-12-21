import 'dart:math';
import 'package:flare_dart/math/mat2d.dart';
import 'package:flare_dart/math/vec2d.dart';
import 'flare.dart';
import 'flare_actor.dart';
import 'flare_controller.dart';
import 'dart:ui';

/// [FlareControls] is a concrete implementation of the [FlareController].
///
/// This controller will provide some basic functionality, such as
/// playing an animation, and advancing every frame. If multiple animations are
/// playing at the same time, this controller will mix them.
class FlareControls extends FlareController {
  /// The current [FlutterActorArtboard].
  FlutterActorArtboard _artboard;

  /// The current [ActorAnimation].
  String _animationName;
  List<String> _toBeRemoved = [];
  final double _mixSeconds = 0.1;

  /// The [FlareAnimationLayer]s currently active.
  final List<FlareAnimationLayer> _animationLayers = [];

  /// Called at initialization time, it stores the reference
  /// to the current [FlutterActorArtboard].
  @override
  void initialize(FlutterActorArtboard artboard) {
    _artboard = artboard;
  }

  /// Listen for when the animation called [name] has completed.
  void onCompleted(String name) {}

  /// Add the [FlareAnimationLayer] of the animation named [name],
  /// to the end of the list of currently playing animation layers.
  void play(String name, {double mix = 1.0, double mixSeconds = 0.2}) {
    _animationName = name;
    if (_animationName != null && _artboard != null) {
      ActorAnimation animation = _artboard.getAnimation(_animationName);
      if (animation != null) {
        _animationLayers.add(FlareAnimationLayer()
          ..name = _animationName
          ..animation = animation
          ..mix = mix
          ..mixSeconds = mixSeconds);
        isActive.value = true;
      }
    }
  }

  void stop(String name) {
    _toBeRemoved.add(name);
  }

  // Storage for our matrix to get global Flutter coordinates into Flare world coordinates.
  Mat2D globalToFlareWorld = Mat2D();
  List<String> deepHitTest(Offset point) {
    Vec2D pointGlobal = Vec2D.fromValues(point.dx, point.dy);
    Vec2D pointFlare = Vec2D();
    Vec2D.transformMat2D(pointFlare, pointGlobal, globalToFlareWorld);
    return _artboard.deepHitTest(Offset(pointFlare[0], pointFlare[1]));
  }

  @override
  void setViewTransform(Mat2D viewTransform) {
    Mat2D.invert(globalToFlareWorld, viewTransform);
  }

  /// Advance all the [FlareAnimationLayer]s that are currently controlled
  /// by this object, and mixes them accordingly.
  ///
  /// If an animation completes during the current frame (and doesn't loop),
  /// the [onCompleted()] callback will be triggered.
  @override
  bool advance(FlutterActorArtboard artboard, double elapsed) {
    /// List of completed animations during this frame.
    List<FlareAnimationLayer> completed = [];
    //remove all stopped animations
    for (final String animationName in _toBeRemoved) {
      _animationLayers.removeWhere((animation) =>
            animation.name == animationName);
      onCompleted(animationName);
    }
    _toBeRemoved.clear();

    /// This loop will mix all the currently active animation layers so that,
    /// if an animation is played on top of the current one, it'll smoothly mix
    ///  between the two instead of immediately switching to the new one.
    for (int i = 0; i < _animationLayers.length; i++) {
      FlareAnimationLayer layer = _animationLayers[i];
      layer.mix += elapsed;
      layer.time += elapsed;

      double mix = (_mixSeconds == null || _mixSeconds == 0.0)
          ? 1.0
          : min(1.0, layer.mix / _mixSeconds);

      /// Loop the time if needed.
      if (layer.animation.isLooping) {
        layer.time %= layer.animation.duration;
      }

      /// Apply the animation with the current mix.
      layer.animation.apply(layer.time, _artboard, mix);

      /// Add (non-looping) finished animations to the list.
      if (layer.time > layer.animation.duration) {
        completed.add(layer);
      }
    }

    /// Notify of the completed animations.
    for (final FlareAnimationLayer animation in completed) {
      _animationLayers.remove(animation);
      onCompleted(animation.name);
    }
    return _animationLayers.isNotEmpty;
  }
}
