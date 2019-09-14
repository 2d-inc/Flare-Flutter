import 'package:flare_flutter/flare.dart';
import 'package:flare_flutter/flare_render_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flare_dart/math/mat2d.dart';
import 'package:flare_dart/math/aabb.dart';

/// Triggers a [FlareSpammerActor] to fire an animation
class FlareSpammerController extends ChangeNotifier {
  void trigger() {
    notifyListeners();
  }
}

/// Allows spamming of multiple animations simultaneously. Useful for
/// firing multiple like animations simultaneously similar to hearts
/// in Facebook live streams.
class FlareSpammerActor extends LeafRenderObjectWidget {
  const FlareSpammerActor(
    this.filename, {
    @required this.animationBuilder,
    @required this.controller,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.snapToEnd = false,
    this.artboard,
  });

  /// Name of the Flare file to be loaded from the AssetBundle.
  final String filename;

  /// The name of the artboard to display.
  final String artboard;

  /// The name of the animation to play. Provides the number of currently
  /// playing animations on screen.
  final String Function(int count) animationBuilder;

  /// When true, the animation will be applied at the end of its duration.
  final bool snapToEnd;

  /// The BoxFit strategy used to scale the Flare content into the
  /// bounds of this widget.
  final BoxFit fit;

  /// The alignment that will be applied in conjuction to the [fit] to align
  /// the Flare content within the bounds of this widget.
  final Alignment alignment;

  final FlareSpammerController controller;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _FlareSpammerRenderObject(animationBuilder)
      ..assetBundle = DefaultAssetBundle.of(context)
      ..filename = filename
      ..fit = fit
      ..alignment = alignment
      ..controller = controller;
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _FlareSpammerRenderObject renderObject) {
    renderObject
      ..assetBundle = DefaultAssetBundle.of(context)
      ..filename = filename
      ..fit = fit
      ..alignment = alignment
      ..controller = controller;
  }

  @override
  void didUnmountRenderObject(
      covariant _FlareSpammerRenderObject renderObject) {
    renderObject.dispose();
  }
}

class _RepaintAnimation {
  final ActorAnimation animation;
  double time = 0.0;
  void apply(FlutterActorArtboard artboard) {
    animation.apply(time, artboard, 1.0);
  }

  double get duration => animation.duration;
  bool get isDone => time >= animation.duration;
  bool get hasAnimation => animation != null;

  _RepaintAnimation(this.animation);
}

/// Does the heavy lifting
class _FlareSpammerRenderObject extends FlareRenderBox {
  _FlareSpammerRenderObject(this.animationBuilder);

  final String Function(int) animationBuilder;

  String _filename;
  FlutterActor _actor;
  FlareSpammerController _controller;

  FlareSpammerController get controller => _controller;
  set controller(FlareSpammerController value) {
    if (_controller == value) {
      return;
    }
    _controller = value;
    _controller.addListener(fireHeart);
  }

  void fireHeart() {
    final newAnimation = _RepaintAnimation(
      _artboard?.getAnimation(
        animationBuilder(_repaintAnimations.length),
      ),
    );

    if (newAnimation.hasAnimation) {
      _repaintAnimations.add(newAnimation);
    }
  }

  final List<_RepaintAnimation> _repaintAnimations = [];

  FlutterActorArtboard _artboard;
  AABB _setupAABB;

  void updateBounds() {
    if (_artboard != null) {
      _setupAABB = _artboard.artboardAABB();
    }
  }

  /// We're playing if we're not paused and our controller is active (or
  /// there's no controller) or there are animations running.
  @override
  bool get isPlaying => _repaintAnimations.isNotEmpty;

  @override
  void onUnload() {
    _repaintAnimations.clear();
    controller.removeListener(fireHeart);
  }

  String get filename => _filename;
  set filename(String value) {
    if (value == _filename) {
      return;
    }
    _filename = value;

    if (_filename == null) {
      markNeedsPaint();
    }
    // file will change, let's clear out old animations.
    _repaintAnimations.clear();
    load();
  }

  bool _instanceArtboard() {
    if (_actor == null || _actor.artboard == null) {
      return false;
    }
    FlutterActorArtboard artboard =
        _actor.artboard.makeInstance() as FlutterActorArtboard;
    artboard.initializeGraphics();
    _artboard = artboard;
    _artboard.advance(0.0);
    updateBounds();
    markNeedsPaint();
    return true;
  }

  @override
  Future<void> load() async {
    if (_filename == null) {
      return;
    }
    _actor = await loadFlare(_filename);
    if (_actor == null || _actor.artboard == null) {
      return;
    }
    _instanceArtboard();
  }

  @override
  void advance(double elapsedSeconds) {
    // advance just moves every animation forward
    if (isPlaying) {
      for (final _RepaintAnimation animation in _repaintAnimations) {
        animation.time += elapsedSeconds;
      }
    }

    if (_artboard != null) {
      _artboard.advance(elapsedSeconds);
    }
  }

  @override
  AABB get aabb => _setupAABB;

  @override
  void prePaint(Canvas canvas, Offset offset) {
    // disable clipping for now
    //   canvas.clipRect(offset & size);
  }

  @override
  void paintFlare(Canvas canvas, Mat2D viewTransform) {
    if (_artboard == null) {
      return;
    }

    // Apply, paint, and prune.
    List<_RepaintAnimation> prune = [];
    for (final _RepaintAnimation animation in _repaintAnimations) {
      animation.apply(_artboard);
      // Don't have a sense of elapsed time here, so just pass 0 for time.
      _artboard.advance(0);
      _artboard.draw(canvas);
      if (animation.isDone) {
        prune.add(animation);
      }
    }
    for (final _RepaintAnimation animation in prune) {
      _repaintAnimations.remove(animation);
    }
  }
}
