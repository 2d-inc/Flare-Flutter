import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flare_dart/math/aabb.dart';
import 'package:flare_dart/math/mat2d.dart';
import 'package:flare_dart/math/vec2d.dart';

import 'asset_provider.dart';
import 'flare.dart';
import 'flare_cache.dart';
import 'flare_cache_asset.dart';

/// A render box for Flare content.
abstract class FlareRenderBox extends RenderBox {
  BoxFit _fit;
  Alignment _alignment;
  int _frameCallbackID;
  double _lastFrameTime = 0.0;
  final Set<FlareCacheAsset> _assets = {};
  bool _useIntrinsicSize = false;

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

  Size _intrinsicSize;
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

  bool get isPlaying;

  BoxFit get fit => _fit;
  set fit(BoxFit value) {
    if (value != _fit) {
      _fit = value;
      markNeedsPaint();
    }
  }

  void updatePlayState() {
    if (isPlaying && attached) {
      markNeedsPaint();
    } else {
      _lastFrameTime = 0;
      if (_frameCallbackID != null) {
        SchedulerBinding.instance.cancelFrameCallbackWithId(_frameCallbackID);
      }
    }
  }

  Alignment get alignment => _alignment;
  set alignment(Alignment value) {
    if (value != _alignment) {
      _alignment = value;
      markNeedsPaint();
    }
  }

  @override
  bool get sizedByParent => !_useIntrinsicSize || _intrinsicSize == null;

  @override
  void performLayout() {
    if (!sizedByParent) {
      size = constraints.constrain(_intrinsicSize);
    }
  }

  @override
  bool hitTestSelf(Offset screenOffset) => true;

  @override
  void performResize() {
    size = _useIntrinsicSize ? constraints.smallest : constraints.biggest;
  }

  @override
  void detach() {
    super.detach();
    dispose();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    updatePlayState();
    if (_assets.isEmpty) {
      load();
    }
  }

  void dispose() {
    updatePlayState();
    _unload();
  }

  void _beginFrame(Duration timestamp) {
    _frameCallbackID = null;
    final double t =
        timestamp.inMicroseconds / Duration.microsecondsPerMillisecond / 1000.0;
    double elapsedSeconds = _lastFrameTime == 0.0 ? 0.0 : t - _lastFrameTime;
    _lastFrameTime = t;

    advance(elapsedSeconds);
    if (!isPlaying) {
      _lastFrameTime = 0.0;
    }
    markNeedsPaint();
  }

  /// Get the Axis Aligned Bounding Box that encompasses the world space scene
  AABB get aabb;

  void paintFlare(Canvas canvas, Mat2D viewTransform);
  void prePaint(Canvas canvas, Offset offset) {}
  void postPaint(Canvas canvas, Offset offset) {}

  @override
  void paint(PaintingContext context, Offset offset) {
    if (isPlaying) {
      // Paint again
      if (_frameCallbackID != null) {
        SchedulerBinding.instance.cancelFrameCallbackWithId(_frameCallbackID);
      }
      _frameCallbackID =
          SchedulerBinding.instance.scheduleFrameCallback(_beginFrame);
    }

    final Canvas canvas = context.canvas;

    AABB bounds = aabb;
    if (bounds != null) {
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
  }

  /// Advance animations, physics, etc by elapsedSeconds.
  void advance(double elapsedSeconds);

  bool _isLoading = false;
  bool _reloadQueued = false;
  bool get isLoading => _isLoading;

  bool warmLoad() {
    return false;
  }

  /// Prevent loading when the renderbox isn't attached. This prevents
  /// unneccesarily hitting an async path during load. A warmLoad would fail
  /// which then falls back to a coldLoad. Due to the async nature, any further
  /// sync calls would be blocked as we gate load with _isLoading.
  bool get canLoad => attached;

  Future<void> coldLoad() async {}

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

  void onUnload() {}

  /// Load a flare file from cache
  FlutterActor getWarmFlare(AssetProvider assetProvider) {
    if (assetProvider == null) {
      return null;
    }

    FlareCacheAsset asset = getWarmActor(assetProvider);

    if (!attached || asset == null) {
      return null;
    }
    _assets.add(asset);
    asset.ref();
    return asset.actor;
  }

  /// Load a flare file from cache
  Future<FlutterActor> loadFlare(AssetProvider assetProvider) async {
    if (assetProvider == null) {
      return null;
    }

    FlareCacheAsset asset = await cachedActor(assetProvider);

    if (!attached || asset == null) {
      return null;
    }
    _assets.add(asset);
    asset.ref();
    return asset.actor;
  }
}
