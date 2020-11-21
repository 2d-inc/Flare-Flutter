import 'dart:math';
import 'package:flare_dart/math/mat2d.dart';
import 'flare.dart';
import 'flare_actor.dart';
import 'flare_controller.dart';

/// [TimedAnimation] holds a reference to [FlareAnimationLayer]s
/// and [currentTime] maintains that layers current animation timeline
/// for mixing purposes
class TimedAnimation {
  FlareAnimationLayer layer;
  double currentTime; // how many seconds have elapsed
}

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

  /// The [TimedAnimation]s currently active.
  final List<TimedAnimation> _animations = [];

  /// Used as a reference for each animation layer
  /// to stay in sync
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
      int layerIndex = _animations.indexWhere((ani) => ani.layer.name == name);
      ActorAnimation animation = _artboard.getAnimation(_animationName);

      if (animation != null && layerIndex == -1) {
        _animations.add(TimedAnimation()
        ..layer = (FlareAnimationLayer()
          ..name = _animationName
          ..animation = animation
          ..mix = mix
          ..mixSeconds = mixSeconds)
        ..currentTime = mix * mixSeconds);
        isActive.value = true;
      } else if (layerIndex >= 0) {
        /// If we already have reference to this, update the seconds
        _animations[layerIndex].layer.mixSeconds = mixSeconds;
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
    List<TimedAnimation> completed = [];

    _ticker += elapsed;

    /// This loop will mix all the currently active animation layers so that,
    /// if an animation is played on top of the current one, it'll smoothly mix
    /// between the two instead of immediately switching to the new one.
    for (int i = 0; i < _animations.length; i++) {
      FlareAnimationLayer layer = _animations[i].layer;
      layer.time = _ticker;
      _animations[i].currentTime += layer.name == _animationName ? elapsed : -elapsed;
      _animations[i].currentTime = max(0.0, min(layer.mixSeconds, _animations[i].currentTime));

      layer.mix = max(0.0, min(1.0, _animations[i].currentTime / layer.mixSeconds));

      /// Loop the time if needed.
      if (layer.animation.isLooping) {
        layer.time %= layer.animation.duration;
      }

      /// Apply the animation with the current mix.
      layer.animation.apply(layer.time, _artboard, layer.mix);

      /// Axe it after it's finished mixing
      if (layer.mix == 0) {
        completed.add(_animations[i]);
      }
    }

    /// Notify of the completed animations.
    for (final TimedAnimation animation in completed) {
      _animations.remove(animation);
      onCompleted(animation.layer.name);
    }
    return _animations.isNotEmpty;
  }
}
