import 'dart:math';
import 'dart:typed_data';
import 'package:flare_flutter/flare_render_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flare_dart/actor_drawable.dart';
import 'package:flare_dart/math/mat2d.dart';
import 'package:flare_dart/math/aabb.dart';
import 'flare.dart';
import 'flare_controller.dart';

typedef void FlareCompletedCallback(String name);

class FlareActor extends LeafRenderObjectWidget {
  /// Name of the Flare file to be loaded from the AssetBundle.
  final String filename;

  /// The name of the artboard to display.
  final String artboard;

  /// The name of the animation to play.
  final String animation;

  /// When true, the animation will be applied at the end of its duration.
  final bool snapToEnd;

  /// The BoxFit strategy used to scale the Flare content into the
  /// bounds of this widget.
  final BoxFit fit;

  /// The alignment that will be applied in conjuction to the [fit] to align
  /// the Flare content within the bounds of this widget.
  final Alignment alignment;

  /// When true, animations do not advance.
  final bool isPaused;

  /// When true, the Flare content will be clipped against the bounds of this
  /// widget.
  final bool shouldClip;

  /// The [FlareController] used to drive animations/mixing/procedural hierarchy
  /// manipulation of the Flare contents.
  final FlareController controller;

  /// Callback invoked when [animation] has completed. If [animation] is looping
  /// this callback is never invoked.
  final FlareCompletedCallback callback;

  /// The color to override any fills/strokes with.
  final Color color;

  /// The name of the node to use to determine the bounds of the content.
  /// When null it will default to the bounds of the artboard.
  final String boundsNode;

  /// When true the intrinsic size of the artboard will be used as the
  /// dimensions of this widget.
  final bool sizeFromArtboard;

  const FlareActor(
    this.filename, {
    this.boundsNode,
    this.animation,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.isPaused = false,
    this.snapToEnd = false,
    this.controller,
    this.callback,
    this.color,
    this.shouldClip = true,
    this.sizeFromArtboard = false,
    this.artboard,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return FlareActorRenderObject()
      ..assetBundle = DefaultAssetBundle.of(context)
      ..filename = filename
      ..fit = fit
      ..alignment = alignment
      ..animationName = animation
      ..snapToEnd = snapToEnd
      ..isPaused = isPaused
      ..controller = controller
      ..completed = callback
      ..color = color
      ..shouldClip = shouldClip
      ..boundsNodeName = boundsNode
      ..useIntrinsicSize = sizeFromArtboard
      ..artboardName = artboard;
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant FlareActorRenderObject renderObject) {
    renderObject
      ..assetBundle = DefaultAssetBundle.of(context)
      ..filename = filename
      ..fit = fit
      ..alignment = alignment
      ..animationName = animation
      ..snapToEnd = snapToEnd
      ..isPaused = isPaused
      ..color = color
      ..shouldClip = shouldClip
      ..boundsNodeName = boundsNode
      ..useIntrinsicSize = sizeFromArtboard
      ..artboardName = artboard;
  }

  @override
  void didUnmountRenderObject(covariant FlareActorRenderObject renderObject) {
    renderObject.dispose();
  }
}

class FlareAnimationLayer {
  String name;
  ActorAnimation animation;
  double time = 0.0, mix = 0.0, mixSeconds = 0.2;
  void apply(FlutterActorArtboard artboard) {
    animation.apply(time, artboard, mix);
  }

  double get duration => animation.duration;
  bool get isDone => time >= animation.duration;
}

class FlareActorRenderObject extends FlareRenderBox {
  Mat2D _lastControllerViewTransform;
  String _filename;
  String _artboardName;
  String _animationName;
  String _boundsNodeName;
  FlareController _controller;
  FlareCompletedCallback _completedCallback;
  bool snapToEnd = false;
  bool _isPaused = false;
  FlutterActor _actor;

  String get artboardName => _artboardName;
  set artboardName(String name) {
    if (_artboardName == name) {
      return;
    }
    _artboardName = name;
    _instanceArtboard();
  }

  bool get isPaused => _isPaused;
  set isPaused(bool value) {
    if (_isPaused == value) {
      return;
    }
    _isPaused = value;
    updatePlayState();
  }

  final List<FlareAnimationLayer> _animationLayers = [];
  bool shouldClip;

  FlutterActorArtboard _artboard;
  AABB _setupAABB;

  Color _color;

  Color get color => _color;
  set color(Color value) {
    if (value != _color) {
      _color = value;
      if (_artboard != null) {
        _artboard.overrideColor = value == null
            ? null
            : Float32List.fromList([
                value.red / 255.0,
                value.green / 255.0,
                value.blue / 255.0,
                value.opacity
              ]);
      }
      markNeedsPaint();
    }
  }

  String get boundsNodeName => _boundsNodeName;
  set boundsNodeName(String value) {
    if (_boundsNodeName == value) {
      return;
    }
    _boundsNodeName = value;
    if (_artboard != null) {
      ActorNode node = _artboard.getNode(_boundsNodeName);
      if (node is ActorDrawable) {
        _setupAABB = node.computeAABB();
      }
    }
  }

  void updateBounds() {
    if (_artboard != null) {
      ActorNode node;
      if (_boundsNodeName != null &&
          (node = _artboard.getNode(_boundsNodeName)) is ActorDrawable) {
        _setupAABB = (node as ActorDrawable).computeAABB();
      } else {
        _setupAABB = _artboard.artboardAABB();
      }
    }
  }

  String get animationName => _animationName;
  set animationName(String value) {
    if (value != _animationName) {
      _animationName = value;
      _updateAnimation();
    }
  }

  /// We're playing if we're not paused and our controller is active (or
  /// there's no controller) or there are animations running.
  @override
  bool get isPlaying =>
      !_isPaused &&
      ((_controller?.isActive?.value ?? false) || _animationLayers.isNotEmpty);

  void onControllerActiveChange() {
    updatePlayState();
  }

  FlareController get controller => _controller;
  set controller(FlareController c) {
    if (_controller != c) {
      _lastControllerViewTransform = c == null ? null : Mat2D();
      _controller?.isActive?.removeListener(onControllerActiveChange);
      _controller = c;
      _controller?.isActive?.addListener(onControllerActiveChange);
      if (_controller != null && _artboard != null) {
        _controller.initialize(_artboard);
      }
    }
  }

  @override
  void onUnload() {
    _animationLayers.length = 0;
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
    _animationLayers.clear();
    load();
  }

  bool _instanceArtboard() {
    if (_actor == null || _actor.artboard == null) {
      return false;
    }
    FlutterActorArtboard artboard = _actor
        .getArtboard(_artboardName)
        .makeInstance() as FlutterActorArtboard;
    artboard.initializeGraphics();
    _artboard = artboard;
    intrinsicSize = Size(artboard.width, artboard.height);
    _artboard.overrideColor = _color == null
        ? null
        : Float32List.fromList([
            _color.red / 255.0,
            _color.green / 255.0,
            _color.blue / 255.0,
            _color.opacity
          ]);
    _artboard.advance(0.0);
    updateBounds();

    if (_controller != null) {
      _controller.initialize(_artboard);
    }
    _updateAnimation(onlyWhenMissing: true);
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

  FlareCompletedCallback get completed => _completedCallback;
  set completed(FlareCompletedCallback value) {
    if (_completedCallback != value) {
      _completedCallback = value;
    }
  }

  @override
  void advance(double elapsedSeconds) {
    if (isPlaying) {
      int lastFullyMixed = -1;
      double lastMix = 0.0;

      List<FlareAnimationLayer> completed = [];

      for (int i = 0; i < _animationLayers.length; i++) {
        FlareAnimationLayer layer = _animationLayers[i];

        if (snapToEnd && !layer.animation.isLooping) {
          layer.mix = 1.0;
          layer.time = layer.duration;
        } else {
          layer.mix += elapsedSeconds;
          layer.time += elapsedSeconds;
        }

        lastMix = (layer.mixSeconds == null || layer.mixSeconds == 0.0)
            ? 1.0
            : min(1.0, layer.mix / layer.mixSeconds);
        if (layer.animation.isLooping) {
          layer.time %= layer.animation.duration;
        }
        layer.animation.apply(layer.time, _artboard, lastMix);
        if (lastMix == 1.0) {
          lastFullyMixed = i;
        }
        if (layer.time > layer.animation.duration) {
          completed.add(layer);
        }
      }

      if (lastFullyMixed != -1) {
        _animationLayers.removeRange(0, lastFullyMixed);
      }
      if (animationName == null &&
          _animationLayers.length == 1 &&
          lastMix == 1.0) {
        // Remove remaining animations.
        _animationLayers.removeAt(0);
      }
      for (final FlareAnimationLayer animation in completed) {
        _animationLayers.remove(animation);
        if (_completedCallback != null) {
          _completedCallback(animation.name);
        }
      }
    }

    if (_artboard != null &&
        _controller != null &&
        !_controller.advance(_artboard, elapsedSeconds)) {
      _controller?.isActive?.value = false;
    }

    if (_artboard != null) {
      _artboard.advance(elapsedSeconds);
    }
  }

  @override
  AABB get aabb => _setupAABB;

  @override
  void prePaint(Canvas canvas, Offset offset) {
    if (shouldClip) {
      canvas.clipRect(offset & size);
    }
  }

  @override
  void paintFlare(Canvas canvas, Mat2D viewTransform) {
    if (_artboard == null) {
      return;
    }
    if (controller != null &&
        !Mat2D.areEqual(_lastControllerViewTransform, viewTransform)) {
      Mat2D.copy(_lastControllerViewTransform, viewTransform);
      controller?.setViewTransform(viewTransform);
    }

    _artboard.draw(canvas);
  }

  void _updateAnimation({bool onlyWhenMissing = false}) {
    if (onlyWhenMissing && _animationLayers.isNotEmpty) {
      return;
    }
    if (_animationName != null && _artboard != null) {
      ActorAnimation animation = _artboard.getAnimation(_animationName);
      if (animation != null) {
        _animationLayers.add(FlareAnimationLayer()
          ..name = _animationName
          ..animation = animation
          ..mix = 1.0
          ..mixSeconds = 0.2);
        animation.apply(0.0, _artboard, 1.0);
        _artboard.advance(0.0);
        updatePlayState();
      }
    }
  }
}
