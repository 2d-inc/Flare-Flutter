import 'dart:math';

import 'package:flare_flutter/asset_provider.dart';
import 'package:flare_flutter/base/math/aabb.dart';
import 'package:flare_flutter/base/math/mat2d.dart';
import 'package:flare_flutter/base/math/vec2d.dart';
import 'package:flare_flutter/flare.dart';
import 'package:flare_flutter/flare_cache.dart';
import 'package:flare_flutter/flare_cache_asset.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

/// A render box for Flare content.
abstract class FlareRenderBox extends RenderBox {
  static const double _notPlayingFlag = -1;
  BoxFit _fit = BoxFit.contain;
  Alignment _alignment = Alignment.center;
  int _frameCallbackID = -1;
  double _lastFrameTime = _notPlayingFlag;
  final Set<FlareCacheAsset> _assets = {};
  bool _useIntrinsicSize = false;

  Size _intrinsicSize = Size.zero;
  bool _isLoading = false;

  bool _reloadQueued = false;

  /// Get the Axis Aligned Bounding Box that encompasses the world space scene
  AABB get aabb;
  Alignment get alignment => _alignment;

  set alignment(Alignment value) {
    if (value != _alignment) {
      _alignment = value;
      markNeedsPaint();
    }
  }

  /// Prevent loading when the renderbox isn't attached. This prevents
  /// unneccesarily hitting an async path during load. A warmLoad would fail
  /// which then falls back to a coldLoad. Due to the async nature, any further
  /// sync calls would be blocked as we gate load with _isLoading.
  bool get canLoad => attached;
  BoxFit get fit => _fit;

  set fit(BoxFit value) {
    if (value != _fit) {
      _fit = value;
      markNeedsPaint();
    }
  }

  Size get intrinsicSize => _intrinsicSize;
  set intrinsicSize(Size value) {
    if (_intrinsicSize == value) {
      return;
    }
    _intrinsicSize = value;
    if (parent != null) {
      markNeedsLayoutForSizedByParentChange();
    }
  }

  bool get isLoading => _isLoading;

  bool get isPlaying;

  @override
  bool get sizedByParent => !_useIntrinsicSize || _intrinsicSize == Size.zero;

  bool get useIntrinsicSize => _useIntrinsicSize;

  set useIntrinsicSize(bool value) {
    if (_useIntrinsicSize == value) {
      return;
    }
    _useIntrinsicSize = value;
    if (parent != null) {
      markNeedsLayoutForSizedByParentChange();
    }
  }

  /// Advance animations, physics, etc by elapsedSeconds.
  void advance(double elapsedSeconds);

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    updatePlayState();
    if (_assets.isEmpty) {
      load();
    }
  }

  Future<void> coldLoad() async {}

  @override
  void detach() {
    super.detach();
    dispose();
  }

  void dispose() {
    updatePlayState();
    _unload();
  }

  /// Load a flare file from cache
  FlutterActor? getWarmFlare(AssetProvider assetProvider) {
    var asset = getWarmActor(assetProvider);
    if (!attached || asset == null) {
      return null;
    }
    _assets.add(asset);
    asset.ref();
    return asset.actor;
  }

  @override
  bool hitTestSelf(Offset screenOffset) => true;

  /// Trigger the loading process. This will attempt a sync warm load,
  /// optimizing for the case where the assets we need are already available.
  /// This allows widgets using this render object to draw immediately and not
  /// draw any empty frames.
  ///
  void load() {
    if (!canLoad) {
      return;
    }
    if (_isLoading) {
      _reloadQueued = true;
      return;
    }
    _isLoading = true;
    _unload();

    // Try a sync warm load in case we already have what we need.
    if (!warmLoad()) {
      coldLoad().then((_) {
        _completeLoad();
      });
    } else {
      _completeLoad();
    }
  }

  /// Load a flare file from cache
  Future<FlutterActor?> loadFlare(AssetProvider assetProvider) async {
    FlareCacheAsset asset = await cachedActor(assetProvider);

    if (!attached) {
      return null;
    }
    _assets.add(asset);
    asset.ref();
    return asset.actor;
  }

  void onUnload() {}
  @override
  void paint(PaintingContext context, Offset offset) {
    if (isPlaying) {
      // Paint again
      if (_frameCallbackID != -1) {
        SchedulerBinding.instance.cancelFrameCallbackWithId(_frameCallbackID);
      }
      _frameCallbackID =
          SchedulerBinding.instance.scheduleFrameCallback(_beginFrame) ?? -1;
    }

    final Canvas canvas = context.canvas;

    AABB bounds = aabb;
    double contentWidth = bounds[2] - bounds[0];
    double contentHeight = bounds[3] - bounds[1];
    double x = -1 * bounds[0] -
        contentWidth / 2.0 -
        (_alignment.x * contentWidth / 2.0);
    double y = -1 * bounds[1] -
        contentHeight / 2.0 -
        (_alignment.y * contentHeight / 2.0);

    double scaleX = 1.0, scaleY = 1.0;

    canvas.save();
    prePaint(canvas, offset);

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

    canvas.translate(
      offset.dx + size.width / 2.0 + (_alignment.x * size.width / 2.0),
      offset.dy + size.height / 2.0 + (_alignment.y * size.height / 2.0),
    );

    canvas.scale(scaleX, scaleY);
    canvas.translate(x, y);

    paintFlare(canvas, transform);

    canvas.restore();
    postPaint(canvas, offset);
  }

  void paintFlare(Canvas canvas, Mat2D viewTransform);

  @override
  void performLayout() {
    if (!sizedByParent) {
      size = constraints.constrain(_intrinsicSize);
    }
  }

  @override
  void performResize() {
    size = _useIntrinsicSize ? constraints.smallest : constraints.biggest;
  }

  void postPaint(Canvas canvas, Offset offset) {}

  void prePaint(Canvas canvas, Offset offset) {}

  void updatePlayState() {
    if (isPlaying && attached) {
      markNeedsPaint();
    } else {
      _lastFrameTime = _notPlayingFlag;
      if (_frameCallbackID != -1) {
        SchedulerBinding.instance.cancelFrameCallbackWithId(_frameCallbackID);
      }
    }
  }

  bool warmLoad() {
    return false;
  }

  void _beginFrame(Duration timestamp) {
    _frameCallbackID = -1;
    final double t = timestamp.inMicroseconds / Duration.microsecondsPerSecond;
    double elapsedSeconds =
        _lastFrameTime == _notPlayingFlag ? 0.0 : t - _lastFrameTime;
    _lastFrameTime = t;

    advance(elapsedSeconds);
    if (!isPlaying) {
      _lastFrameTime = _notPlayingFlag;
    }
    markNeedsPaint();
  }

  void _completeLoad() {
    // Load is complete, check if a reload was requested
    // during our load, and start it up again
    _isLoading = false;
    if (_reloadQueued) {
      _reloadQueued = false;
      load();
    }
  }

  void _unload() {
    for (final FlareCacheAsset asset in _assets) {
      asset.deref();
    }
    _assets.clear();
    onUnload();
  }
}
