import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flare_dart/actor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flare_dart/actor_drawable.dart';
import 'package:flare_dart/math/mat2d.dart';
import 'package:flare_dart/math/vec2d.dart';
import 'package:flare_dart/math/aabb.dart';
import 'flare.dart';
import 'flare_controller.dart';

typedef void FlareCompletedCallback(String name);

class FlareActor extends LeafRenderObjectWidget {
  final FlareAnimationProvider provider;
  final String animation;
  final BoxFit fit;
  final Alignment alignment;
  final bool isPaused;
  final bool shouldClip;
  final FlareController controller;
  final FlareCompletedCallback callback;
  final Color color;
  final String boundsNode;

  FlareActor(this.provider,
      {this.boundsNode,
      this.animation,
      this.fit = BoxFit.contain,
      this.alignment = Alignment.center,
      this.isPaused = false,
      this.controller,
      this.callback,
      this.color,
      this.shouldClip = true});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return FlareActorRenderObject()
      ..provider = provider
      ..fit = fit
      ..alignment = alignment
      ..animationName = animation
      ..isPlaying = !isPaused
      ..controller = controller
      ..completed = callback
      ..color = color
      ..shouldClip = shouldClip
      ..boundsNodeName = boundsNode;
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant FlareActorRenderObject renderObject) {
    renderObject
      ..provider = provider
      ..fit = fit
      ..alignment = alignment
      ..animationName = animation
      ..isPlaying = !isPaused
      ..color = color
      ..shouldClip = shouldClip
      ..boundsNodeName = boundsNode;
  }

  didUnmountRenderObject(covariant FlareActorRenderObject renderObject) {
    renderObject.dispose();
  }
}

class FlareAnimationLayer {
  String name;
  ActorAnimation animation;
  double time = 0.0, mix = 0.0;

  apply(FlutterActorArtboard artboard) {
    animation.apply(time, artboard, mix);
  }

  get duration => animation.duration;

  get isDone => time >= animation.duration;
}

class FlareActorRenderObject extends RenderBox {
  FlareAnimationProvider _provider;
  BoxFit _fit;
  Alignment _alignment;
  String _animationName;
  String _boundsNodeName;
  FlareController _controller;
  FlareCompletedCallback _completedCallback;
  double _lastFrameTime = 0.0;
  double _mixSeconds = 0.2;

  List<FlareAnimationLayer> _animationLayers = [];
  bool _isPlaying;
  bool shouldClip;

  FlutterActor _actor;
  FlutterActorArtboard _artboard;
  AABB _setupAABB;
  int _frameCallbackID;

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
        _setupAABB = (node as ActorDrawable).computeAABB();
      }
    }
  }

  void dispose() {
    _isPlaying = false;
    updatePlayState();
    _actor = null;
    _controller = null;
  }

  void updateBounds() {
    if (_actor != null) {
      ActorNode node;
      if (_boundsNodeName != null &&
          (node = _artboard.getNode(_boundsNodeName)) is ActorDrawable) {
        _setupAABB = (node as ActorDrawable).computeAABB();
      } else {
        _setupAABB = _artboard.artboardAABB();
      }
    }
  }

  BoxFit get fit => _fit;

  set fit(BoxFit value) {
    if (value != _fit) {
      _fit = value;
      markNeedsPaint();
    }
  }

  bool get isPlaying => _isPlaying;

  set isPlaying(bool value) {
    if (value != _isPlaying) {
      _isPlaying = value;
      updatePlayState();
    }
  }

  updatePlayState() {
    if (_isPlaying && attached) {
      if (_frameCallbackID == null) {
        _frameCallbackID =
            SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
      }
    } else {
      if (_frameCallbackID != null) {
        SchedulerBinding.instance.cancelFrameCallbackWithId(_frameCallbackID);
        _frameCallbackID = null;
      }
      _lastFrameTime = 0.0;
    }
  }

  String get animationName => _animationName;

  set animationName(String value) {
    if (value != _animationName) {
      _animationName = value;
      _updateAnimation();
    }
  }

  FlareController get controller => _controller;

  set controller(FlareController c) {
    if (_controller != c) {
      _controller = c;
      if (_controller != null && _artboard != null) {
        _controller.initialize(_artboard);
      }
    }
  }

  FlareAnimationProvider get provider => _provider;

  set provider(FlareAnimationProvider value) {
    if (value != _provider) {
      _provider = value;
      if (_actor != null) {
        _actor.dispose();
        _actor = null;
        _artboard = null;
      }
      if (_provider == null) {
        markNeedsPaint();
        return;
      }

      FlutterActor actor = FlutterActor();
      actor.loadFromProvider(provider).then((bool success) {
        if (success) {
          _actor = actor;
          _artboard = _actor?.artboard;
          if (_artboard != null) {
            _artboard.initializeGraphics();
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
          }
          if (_controller != null) {
            _controller.initialize(_artboard);
          }
          _updateAnimation(onlyWhenMissing: true);
          markNeedsPaint();
          updatePlayState();
        }
      });
    }
  }

  Alignment get alignment => _alignment;

  set alignment(Alignment value) {
    if (value != _alignment) {
      _alignment = value;
      markNeedsPaint();
    }
  }

  FlareCompletedCallback get completed => _completedCallback;

  set completed(FlareCompletedCallback value) {
    if (_completedCallback != value) {
      _completedCallback = value;
    }
  }

  @override
  bool get sizedByParent => true;

  @override
  bool hitTestSelf(Offset screenOffset) => true;

  @override
  performResize() {
    size = constraints.biggest;
  }

  @override
  void performLayout() {
    super.performLayout();
  }

  @override
  void detach() {
    super.detach();
    updatePlayState();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    updatePlayState();
  }

  void beginFrame(Duration timestamp) {
    _frameCallbackID = null;
    if (_actor == null) {
      return;
    }
    final double t =
        timestamp.inMicroseconds / Duration.microsecondsPerMillisecond / 1000.0;
    if (_lastFrameTime == 0 || _actor == null) {
      _lastFrameTime = t;
      updatePlayState();
      return;
    }

    double elapsedSeconds = t - _lastFrameTime;
    _lastFrameTime = t;

    int lastFullyMixed = -1;
    double lastMix = 0.0;

    List<FlareAnimationLayer> completed = [];

    for (int i = 0; i < _animationLayers.length; i++) {
      FlareAnimationLayer layer = _animationLayers[i];
      layer.mix += elapsedSeconds;
      layer.time += elapsedSeconds;

      lastMix = (_mixSeconds == null || _mixSeconds == 0.0)
          ? 1.0
          : min(1.0, layer.mix / _mixSeconds);
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
    for (FlareAnimationLayer animation in completed) {
      _animationLayers.remove(animation);
      if (_completedCallback != null) {
        _completedCallback(animation.name);
      }
    }

    bool stopPlaying = true;
    if (_animationLayers.length > 0) {
      stopPlaying = false;
    }

    if (_controller != null) {
      if (_controller.advance(_artboard, elapsedSeconds)) {
        stopPlaying = false;
      }
    }

    if (stopPlaying) {
      _isPlaying = false;
    }

    updatePlayState();

    if (_artboard != null) {
      _artboard.advance(elapsedSeconds);
    }

    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final Canvas canvas = context.canvas;

    if (_artboard != null) {
      AABB bounds = _setupAABB;
      double contentWidth = bounds[2] - bounds[0];
      double contentHeight = bounds[3] - bounds[1];
      double x =
          -bounds[0] - contentWidth / 2.0 - (_alignment.x * contentWidth / 2.0);
      double y = -bounds[1] -
          contentHeight / 2.0 -
          (_alignment.y * contentHeight / 2.0);

      double scaleX = 1.0, scaleY = 1.0;

      canvas.save();
      if (this.shouldClip) {
        canvas.clipRect(offset & size);
      }

      switch (_fit) {
        case BoxFit.fill:
          scaleX = size.width / contentWidth;
          scaleY = size.height / contentHeight;
          break;
        case BoxFit.contain:
          double minScale =
              min(size.width / contentWidth, size.height / contentHeight);
          scaleX = scaleY = minScale;
          break;
        case BoxFit.cover:
          double maxScale =
              max(size.width / contentWidth, size.height / contentHeight);
          scaleX = scaleY = maxScale;
          break;
        case BoxFit.fitHeight:
          double minScale = size.height / contentHeight;
          scaleX = scaleY = minScale;
          break;
        case BoxFit.fitWidth:
          double minScale = size.width / contentWidth;
          scaleX = scaleY = minScale;
          break;
        case BoxFit.none:
          scaleX = scaleY = 1.0;
          break;
        case BoxFit.scaleDown:
          double minScale =
              min(size.width / contentWidth, size.height / contentHeight);
          scaleX = scaleY = minScale < 1.0 ? minScale : 1.0;
          break;
      }

      if (_controller != null) {
        Mat2D transform = Mat2D();
        transform[4] =
            offset.dx + size.width / 2.0 + (_alignment.x * size.width / 2.0);
        transform[5] =
            offset.dy + size.height / 2.0 + (_alignment.y * size.height / 2.0);
        Mat2D.scale(transform, transform, Vec2D.fromValues(scaleX, scaleY));
        Mat2D center = Mat2D();
        center[4] = x;
        center[5] = y;
        Mat2D.multiply(transform, transform, center);
        _controller.setViewTransform(transform);
      }

      canvas.translate(
        offset.dx + size.width / 2.0 + (_alignment.x * size.width / 2.0),
        offset.dy + size.height / 2.0 + (_alignment.y * size.height / 2.0),
      );

      canvas.scale(scaleX, scaleY);
      canvas.translate(x, y);
      _artboard.draw(canvas);
      canvas.restore();
    }
  }

  _updateAnimation({bool onlyWhenMissing = false}) {
    if (onlyWhenMissing && _animationLayers.isNotEmpty) {
      return;
    }
    if (_animationName != null && _artboard != null) {
      ActorAnimation animation = _artboard.getAnimation(_animationName);
      if (animation != null) {
        _animationLayers.add(FlareAnimationLayer()
          ..name = _animationName
          ..animation = animation
          ..mix = 1.0);
        animation.apply(0.0, _artboard, 1.0);
        _artboard.advance(0.0);
      }
      updatePlayState();
    }
  }
}


