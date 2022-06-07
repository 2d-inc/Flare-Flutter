import 'dart:math';
import 'dart:typed_data';

import 'package:flare_flutter/asset_provider.dart';
import 'package:flare_flutter/base/actor_drawable.dart';
import 'package:flare_flutter/base/math/aabb.dart';
import 'package:flare_flutter/flare.dart';
import 'package:flare_flutter/flare_controller.dart';
import 'package:flare_flutter/flare_render_box.dart';
import 'package:flare_flutter/provider/asset_flare.dart';
import 'package:flare_flutter/provider/memory_flare.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

typedef void FlareCompletedCallback(String name);

/// A widget that displays a Flare.
///
/// Several constructors are provided for the various ways that a Flare can be
/// specified:
///  * [FlareActor], for obtaining a Flare from an asset [filename].
///  * [FlareActor.asset], for obtaining a Flare from an [AssetProvider].
///  * [FlareActor.bundle], for obtaining a Flare from an [AssetBundle].
///  * [FlareActor.memory], for obtaining a Flare from a [Uint8List].
class FlareActor extends LeafRenderObjectWidget {
  /// Name of the Flare file to be loaded from the AssetBundle.
  final String? filename;

  /// The Flare asset to display.
  final AssetProvider? flareProvider;

  /// The name of the artboard to display.
  final String? artboard;

  /// The name of the animation to play.
  final String? animation;

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
  final FlareController? controller;

  /// Callback invoked when [animation] has completed. If [animation] is looping
  /// this callback is never invoked.
  final FlareCompletedCallback? callback;

  /// The color to override any fills/strokes with.
  final Color? color;

  /// The name of the node to use to determine the bounds of the content.
  /// When null it will default to the bounds of the artboard.
  final String? boundsNode;

  /// When true the intrinsic size of the artboard will be used as the
  /// dimensions of this widget.
  final bool sizeFromArtboard;

  /// When false disables antialiasing on drawables.
  final bool antialias;

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
    this.antialias = true,
  }) : flareProvider = null;

  const FlareActor.asset(
    this.flareProvider, {
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
    this.antialias = true,
  }) : filename = null;

  FlareActor.bundle(
    String name, {
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
    this.antialias = true,
    AssetBundle? bundle,
  })  : filename = null,
        flareProvider = AssetFlare(bundle: bundle ?? rootBundle, name: name);

  FlareActor.memory(
    Uint8List bytes, {
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
    this.antialias = true,
  })  : filename = null,
        flareProvider = MemoryFlare(bytes: bytes);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return FlareActorRenderObject()
      ..assetProvider =
          flareProvider ?? AssetFlare(bundle: rootBundle, name: filename!)
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
      ..artboardName = artboard
      ..useAntialias = antialias;
  }

  @override
  void didUnmountRenderObject(covariant FlareActorRenderObject renderObject) {
    renderObject.dispose();
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant FlareActorRenderObject renderObject) {
    renderObject
      ..assetProvider =
          flareProvider ?? AssetFlare(bundle: rootBundle, name: filename!)
      ..fit = fit
      ..alignment = alignment
      ..animationName = animation
      ..snapToEnd = snapToEnd
      ..isPaused = isPaused
      ..color = color
      ..shouldClip = shouldClip
      ..boundsNodeName = boundsNode
      ..useIntrinsicSize = sizeFromArtboard
      ..artboardName = artboard
      ..useAntialias = antialias;
  }
}

class FlareActorRenderObject extends FlareRenderBox {
  final Mat2D _lastControllerViewTransform = Mat2D();
  AssetProvider? _assetProvider;
  String? _artboardName;
  String? _animationName;
  String? _boundsNodeName;
  FlareController? _controller;
  FlareCompletedCallback? _completedCallback;
  bool snapToEnd = false;
  bool _isPaused = false;
  bool _useAntialias = true;
  FlutterActor? _actor;

  final List<FlareAnimationLayer> _animationLayers = [];
  bool shouldClip = true;

  // _artboard is only available after _actor has loaded.
  late FlutterActorArtboard _artboard;

  // _setupAABB is only available after _actor has loaded.
  late AABB _setupAABB;

  Color? _color;
  @override
  AABB get aabb => _actor == null ? AABB() : _setupAABB;

  String? get animationName => _animationName;
  set animationName(String? value) {
    if (value != _animationName) {
      _animationName = value;
      _updateAnimation();
    }
  }

  String? get artboardName => _artboardName;
  set artboardName(String? name) {
    if (_artboardName == name) {
      return;
    }
    _artboardName = name;
    _instanceArtboard();
  }

  AssetProvider? get assetProvider => _assetProvider;

  set assetProvider(AssetProvider? value) {
    if (value == _assetProvider) {
      return;
    }
    _assetProvider = value;

    markNeedsPaint();
    // file will change, let's clear out old animations.
    _animationLayers.clear();
    load();
  }

  String? get boundsNodeName => _boundsNodeName;

  set boundsNodeName(String? value) {
    if (_boundsNodeName == value) {
      return;
    }
    _boundsNodeName = value;
    updateBounds();
  }

  Color? get color => _color;

  set color(Color? value) {
    if (value != _color) {
      _color = value;
      if (_actor != null) {
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

  FlareCompletedCallback? get completed => _completedCallback;
  set completed(FlareCompletedCallback? value) {
    if (_completedCallback != value) {
      _completedCallback = value;
    }
  }

  FlareController? get controller => _controller;

  set controller(FlareController? c) {
    if (_controller != c) {
      Mat2D.copy(_lastControllerViewTransform, Mat2D());
      _controller?.isActive.removeListener(onControllerActiveChange);
      _controller = c;
      _controller?.isActive.addListener(onControllerActiveChange);
      if (_controller != null && _actor != null) {
        _controller!.initialize(_artboard);
      }
    }
  }

  bool get isPaused => _isPaused;
  set isPaused(bool value) {
    if (_isPaused == value) {
      return;
    }
    _isPaused = value;
    updatePlayState();
  }

  /// We're playing if we're not paused and our controller is active (or
  /// there's no controller) or there are animations running.
  @override
  bool get isPlaying =>
      !_isPaused &&
      ((_controller?.isActive.value ?? false) || _animationLayers.isNotEmpty);

  bool get useAntialias => _useAntialias;
  set useAntialias(bool value) {
    if (value != _useAntialias) {
      _useAntialias = value;
      if (_actor != null) {
        _artboard.antialias = _useAntialias;
      }
      markNeedsPaint();
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

        lastMix = layer.mixSeconds == 0.0
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
          _completedCallback!(animation.name);
        }
      }
    }

    if (_actor != null &&
        _controller != null &&
        !_controller!.advance(_artboard, elapsedSeconds)) {
      _controller?.isActive.value = false;
    }

    // artboard is gauranteed to be available once actor is
    if (_actor != null) {
      _artboard.advance(elapsedSeconds);
    }
  }

  /// Load the necessary Flare file specified by [AssetProvider].
  /// this occurs when the optimal warmLoad fails to find an asset in cache.
  @override
  Future<void> coldLoad() async {
    _actor = await loadFlare(_assetProvider!);
    _instanceArtboard();
  }

  void onControllerActiveChange() {
    updatePlayState();
  }

  @override
  void onUnload() {
    _animationLayers.clear();
  }

  @override
  void paintFlare(Canvas canvas, Mat2D viewTransform) {
    if (_actor == null) {
      return;
    }
    if (!Mat2D.areEqual(_lastControllerViewTransform, viewTransform)) {
      Mat2D.copy(_lastControllerViewTransform, viewTransform);
      controller?.setViewTransform(viewTransform);
    }

    _artboard.draw(canvas);
  }

  @override
  void prePaint(Canvas canvas, Offset offset) {
    if (shouldClip) {
      canvas.clipRect(offset & size);
    }
  }

  void updateBounds() {
    if (_actor != null) {
      ActorNode? node;
      if (_boundsNodeName != null &&
          (node = _artboard.getNode(_boundsNodeName!)) is ActorDrawable) {
        _setupAABB = (node as ActorDrawable).computeAABB();
      } else {
        _setupAABB = _artboard.artboardAABB();
      }
    }
  }

  /// Attempt a warm load, this is the optimal case when the
  /// required asset is already in the cache.
  @override
  bool warmLoad() {
    var actor = getWarmFlare(_assetProvider!);
    if (actor == null) {
      return false;
    }
    _actor = actor;
    return _instanceArtboard();
  }

  bool _instanceArtboard() {
    var sourceArtboard = _actor?.getArtboard(_artboardName);
    if (sourceArtboard == null) {
      return false;
    }

    FlutterActorArtboard artboard =
        sourceArtboard.makeInstance() as FlutterActorArtboard;
    artboard.initializeGraphics();
    _artboard = artboard;
    intrinsicSize = Size(artboard.width, artboard.height);
    _artboard.overrideColor = _color == null
        ? null
        : Float32List.fromList([
            _color!.red / 255.0,
            _color!.green / 255.0,
            _color!.blue / 255.0,
            _color!.opacity
          ]);
    _artboard.antialias = _useAntialias;
    _controller?.initialize(_artboard);
    _animationLayers.clear();
    _updateAnimation(onlyWhenMissing: true);
    // Immediately update the newly instanced artboard and compute
    // bounds so that the widget can take up the necessary space
    advance(0.0);
    updateBounds();

    markNeedsPaint();
    return true;
  }

  void _updateAnimation({bool onlyWhenMissing = false}) {
    if (onlyWhenMissing && _animationLayers.isNotEmpty) {
      return;
    }
    if (_animationName != null && _actor != null) {
      var animation = _artboard.getAnimation(_animationName!);
      if (animation != null) {
        _animationLayers.add(FlareAnimationLayer(_animationName!, animation)
          ..mix = 1.0
          ..mixSeconds = 0.2);
        animation.apply(0.0, _artboard, 1.0);
        _artboard.advance(0.0);
        updatePlayState();
      }
    }
  }
}

class FlareAnimationLayer {
  final String name;
  final ActorAnimation animation;
  double time = 0.0, mix = 0.0, mixSeconds = 0.2;

  FlareAnimationLayer(this.name, this.animation);

  double get duration => animation.duration;

  bool get isDone => time >= animation.duration;
  void apply(FlutterActorArtboard artboard) {
    animation.apply(time, artboard, mix);
  }
}
