import 'dart:math';
import 'flare.dart';
import 'flare_actor.dart';
import 'flare_controller.dart';
import 'package:flare_dart/math/mat2d.dart';

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
  double _mixSeconds = 0.1;

  /// The [FlareAnimationLayer]s currently active.
  List<FlareAnimationLayer> _animationLayers = [];

  /// Called at initialization time, it stores the reference
  /// to the current [FlutterActorArtboard].
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

  void setViewTransform(Mat2D viewTransform) {}

  /// Advance all the [FlareAnimationLayer]s that are currently controlled
  /// by this object, and mixes them accordingly.
  ///
  /// If an animation completes during the current frame (and doesn't loop),
  /// the [onCompleted()] callback will be triggered.
  bool advance(FlutterActorArtboard artboard, double elapsed) {
    int lastFullyMixed = -1;
    double lastMix = 0.0;

    /// List of completed animations during this frame.
    List<FlareAnimationLayer> completed = [];

    /// This loop will mix all the currently active animation layers so that,
    /// if an animation is played on top of the current one, it'll smoothly mix between
    /// the two instead of immediately switching to the new one.
    for (int i = 0; i < _animationLayers.length; i++) {
      FlareAnimationLayer layer = _animationLayers[i];
      layer.mix += elapsed;
      layer.time += elapsed;

      lastMix = (_mixSeconds == null || _mixSeconds == 0.0)
          ? 1.0
          : min(1.0, layer.mix / _mixSeconds);

      /// Loop the time if needed.
      if (layer.animation.isLooping) {
        layer.time %= layer.animation.duration;
      }

      /// Apply the animation with the current mix.
      layer.animation.apply(layer.time, _artboard, lastMix);

      /// Update [lastFullyMixed] with the range of fully
      /// mixed animation layers.
      if (lastMix == 1.0) {
        lastFullyMixed = i;
      }

      /// Add (non-looping) finished animations to the list.
      if (layer.time > layer.animation.duration) {
        completed.add(layer);
      }
    }

    /// Removes the last fully mixed animation, if more than one animation is present.
    /// If only one animation is playing (e.g. idle), nothing happens.
    /// Since animations are added to the end of [_animationLayers],
    /// everything before the last fully mixed animation can be
    /// assumed to be also fully mixed too.
    if (lastFullyMixed != -1) {
      _animationLayers.removeRange(0, lastFullyMixed);
    }
    if (_animationName == null &&
        _animationLayers.length == 1 &&
        lastMix == 1.0) {
      /// Remove remaining animations.
      _animationLayers.removeAt(0);
    }

    /// Notify of the completed animations.
    for (FlareAnimationLayer animation in completed) {
      _animationLayers.remove(animation);
      onCompleted(animation.name);
    }
    return _animationLayers.isNotEmpty;
  }
}
