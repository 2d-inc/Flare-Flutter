import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:nima/nima.dart';
import 'package:nima/nima/animation/actor_animation.dart';
import 'package:nima/nima/math/aabb.dart';

class NimaWidget extends LeafRenderObjectWidget {
  final String _filename;
  final double scrollOffset;
  final Offset touchPosition;

  NimaWidget(this._filename, {Key key, this.scrollOffset, this.touchPosition})
      : super(key: key);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return new NimaRenderObject(_filename, scrollOffset);
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant NimaRenderObject renderObject) {
    renderObject
      ..filename = _filename
      ..scrollOffset = scrollOffset
      ..touchPosition = touchPosition;
  }
}

class NimaRenderObject extends RenderBox {
  String filename;
  String _loadedFilename;
  FlutterActor _actor;
  FlutterActor _actorInstance;
  ActorAnimation _animation;
  double _animationTime;
  double _lastFrameTime = 0.0;
  double _scrollOffset = 0.0;
  AABB _aabb;
  Offset _touchPosition;
  bool _isControlled = false;
  double _scale = 1.0;
  double zoomedIn = 1.0;
  Offset _cameraOffset;

  void beginFrame(Duration timeStamp) {
    final double t =
        timeStamp.inMicroseconds / Duration.microsecondsPerMillisecond / 1000.0;

    if (_lastFrameTime == 0) {
      _lastFrameTime = t;
      SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
      return;
    }

    double elapsed = t - _lastFrameTime;
    _lastFrameTime = t;

    if (_actorInstance != null && _scrollOffset == 0.0) {
      _animationTime += elapsed;
      if (_animation != null) {
        _animation.apply(
            _animationTime % _animation.duration, _actorInstance, 1.0);
      }
      _actorInstance.advance(elapsed);
    }

    markNeedsPaint();
    SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
  }

  NimaRenderObject(this.filename, double scrollOffset) {
    this.scrollOffset = _scrollOffset;
    this._cameraOffset = new Offset(0.0, 0.0);
    SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
  }

  @override
  bool get sizedByParent => true;

  @override
  bool hitTestSelf(Offset screenOffset) => true;

  @override
  void performResize() {
    size = constraints.biggest;
    _touchPosition = new Offset(size.width / 2, size.height / 2);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final Canvas canvas = context.canvas;
    if (_actorInstance == null ||
        (_scrollOffset >= 1.0 || _scrollOffset <= -1.0)) {
      return;
    }
    canvas.save();
    canvas.translate(_scrollOffset * size.width, 0.0);
    canvas.clipRect(offset & size);
    canvas.save();

    double width = _aabb[2] - _aabb[0];
    double height = _aabb[3] - _aabb[1];

    int heightPadding = 90;
    double scale = _isControlled
        ? zoomedIn
        : max(size.width / width, size.height / (height - heightPadding));
    _scale = _scale + (scale - _scale) * 0.05;
    canvas.translate(
        offset.dx + size.width / 2.0, offset.dy + size.height / 2.0);
    canvas.scale(_scale, -_scale);
    canvas.translate(-_aabb[0] - width / 2.0, -_aabb[1] - height / 2.0);

    double nx = _touchPosition.dx / size.width / ui.window.devicePixelRatio;
    double offsetX = (1.0 - nx * 2.0) * 500.0;

    double ny = _touchPosition.dy / size.height / ui.window.devicePixelRatio;
    double offsetY = -(1.0 - ny * 2.0) * heightPadding / 2.0;

    _cameraOffset = new Offset(
        _cameraOffset.dx + (offsetX - _cameraOffset.dx) * 0.1,
        _cameraOffset.dy + (offsetY - _cameraOffset.dy) * 0.1);
    canvas.translate(_cameraOffset.dx, _cameraOffset.dy);
    _actorInstance.draw(canvas);
    canvas.restore();
    double fadeHeight = size.height * 0.75;

    canvas.drawRect(
        new Offset(offset.dx, offset.dy + (size.height - fadeHeight)) &
            new Size(size.width, fadeHeight),
        new ui.Paint()
          ..shader = new ui.Gradient.linear(
              new Offset(0.0, offset.dy + (size.height - fadeHeight)),
              new Offset(0.0, offset.dy + fadeHeight), <Color>[
            const Color.fromARGB(0, 0, 0, 0),
            const Color.fromARGB(128, 0, 0, 0)
          ])
          ..style = ui.PaintingStyle.fill);
    canvas.restore();
  }

  @override
  markNeedsPaint() {
    if (_loadedFilename != filename) {
      _actor = new FlutterActor();
      _loadedFilename = filename;
      _actor.loadFromBundle(filename).then((ok) {
        _actorInstance = _actor;
        _animation = _actor.getAnimation("Robot_Kr2");
        _animationTime = 0.0;

        //	print("AABB ${aabb[0]} ${aabb[1]} ${aabb[2]} ${aabb[3]}");
        if (_actorInstance != null && _animation != null) {
          _animation.apply(
              _animationTime % _animation.duration, _actorInstance, 1.0);
          _actorInstance.advance(0.0);
          _aabb = _actor.computeAABB();
        }
        markNeedsPaint();
      });
    }
    super.markNeedsPaint();
  }

  double get scrollOffset {
    return _scrollOffset;
  }

  set scrollOffset(double v) {
    if (_scrollOffset == v) {
      return;
    }
    _scrollOffset = v;
    markNeedsPaint();
  }

  set touchPosition(Offset t) {
    _isControlled = t != null;
    if (t != _touchPosition) {
      _touchPosition = t ??
          new Offset(ui.window.physicalSize.width / 2,
              ui.window.physicalSize.height / 2);
    }
  }
}
