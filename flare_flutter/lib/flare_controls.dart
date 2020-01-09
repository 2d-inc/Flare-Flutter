import 'dart:math';
import 'package:flare_dart/math/mat2d.dart';
import 'flare.dart';
import 'flare_actor.dart';
import 'flare_controller.dart';

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

  /// The [FlareAnimationLayer]s currently active.
  final List<FlareAnimationLayer> _animationLayers = [];

  double _ticker = 0.0;

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
      int layerIndex = _animationLayers.indexWhere((layer) => layer.name == name);
      ActorAnimation animation = _artboard.getAnimation(_animationName);

      if (animation != null && layerIndex == -1) {
        _animationLayers.add(FlareAnimationLayer()
          ..name = _animationName
          ..animation = animation
          ..mix = mix
          ..mixSeconds = mixSeconds);
        isActive.value = true;
      } else if (layerIndex >= 0) {
        /// If we already have reference to this, update the seconds
        FlareAnimationLayer layer = _animationLayers[layerIndex];
        layer.mixSeconds = mixSeconds;
      }
    }
  }

  @override
  void setViewTransform(Mat2D viewTransform) {}

  /// Advance all the [FlareAnimationLayer]s that are currently controlled
  /// by this object, and mixes them accordingly.
  ///
  /// If an animation completes during the current frame (and doesn't loop),
  /// the [onCompleted()] callback will be triggered.
  @override
  bool advance(FlutterActorArtboard artboard, double elapsed) {
    /// List of completed animations during this frame.
    List<FlareAnimationLayer> completed = [];

    _ticker += elapsed;

    /// This loop will mix all the currently active animation layers so that,
    /// if an animation is played on top of the current one, it'll smoothly mix
    /// between the two instead of immediately switching to the new one.
    for (int i = 0; i < _animationLayers.length; i++) {
      FlareAnimationLayer layer = _animationLayers[i];
      layer.time = _ticker;

      layer.mix += layer.name == _animationName ? elapsed / layer.mixSeconds : -elapsed / layer.mixSeconds;
      layer.mix = max(0.0, min(1.0, layer.mix));

      double mix = (layer.mixSeconds == null || layer.mixSeconds == 0.0)
          ? 1.0
          : max(0.0, min(1.0, layer.mix / layer.mixSeconds));

      /// Loop the time if needed.
      if (layer.animation.isLooping) {
        layer.time %= layer.animation.duration;
      }

      /// Apply the animation with the current mix.
      layer.animation.apply(layer.time, _artboard, mix);

      /// axe it after it's finished mixing
      if (mix == 0) {
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
