library flare_flutter;

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flare_dart/actor_flags.dart';
import 'package:flare_dart/actor_image.dart';
import 'package:flare_dart/actor_mask.dart';
import 'package:flare_dart/math/aabb.dart';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:flare_dart/actor_component.dart';
import 'package:flare_dart/actor.dart';
import 'package:flare_dart/actor_artboard.dart';
import 'package:flare_dart/actor_shape.dart';
import 'package:flare_dart/actor_path.dart';
import 'package:flare_dart/actor_ellipse.dart';
import 'package:flare_dart/actor_polygon.dart';
import 'package:flare_dart/actor_rectangle.dart';
import 'package:flare_dart/actor_star.dart';
import 'package:flare_dart/actor_triangle.dart';
import 'package:flare_dart/actor_color.dart';
import 'package:flare_dart/actor_drawable.dart';
import 'package:flare_dart/math/mat2d.dart';
import 'package:flare_dart/math/vec2d.dart';
import 'package:flare_dart/path_point.dart';
import 'package:flare_dart/actor_drop_shadow.dart';
import 'package:flare_dart/actor_inner_shadow.dart';
import 'package:flare_dart/actor_layer_effect_renderer.dart';
import 'trim_path.dart';

export 'package:flare_dart/animation/actor_animation.dart';
export 'package:flare_dart/actor_node.dart';

abstract class FlutterActorDrawable {
  ui.BlendMode _blendMode;
  int get blendModeId {
    return _blendMode.index;
  }

  set blendModeId(int index) {
    blendMode = ui.BlendMode.values[index];
  }

  ui.BlendMode get blendMode => _blendMode;
  set blendMode(ui.BlendMode mode) {
    if (_blendMode == mode) {
      return;
    }
    _blendMode = mode;
    onBlendModeChanged(_blendMode);
  }

  void onBlendModeChanged(ui.BlendMode blendMode);

  void draw(ui.Canvas canvas);

  List<List<ClipShape>> get clipShapes;
  ActorArtboard get artboard;

  void clip(ui.Canvas canvas) {
    for (final List<ClipShape> clips in clipShapes) {
      for (final ClipShape clipShape in clips) {
        var shape = clipShape.shape;
        if (shape.renderCollapsed) {
          continue;
        }
        if (clipShape.intersect) {
          canvas.clipPath((shape as FlutterActorShape).path);
        } else {
          var artboardRect = Rect.fromLTWH(
              artboard.origin[0] * artboard.width,
              artboard.origin[1] * artboard.height,
              artboard.width,
              artboard.height);

          if (shape.fill != null && shape.fill.fillRule == FillRule.evenOdd) {
            // One single clip path with subtraction rect and all sub paths.
            var clipPath = ui.Path();
            clipPath.addRect(artboardRect);
            for (final path in shape.paths) {
              clipPath.addPath((path as FlutterPath).path, ui.Offset.zero,
                  matrix4: path.pathTransform?.mat4);
            }
            clipPath.fillType = PathFillType.evenOdd;
            canvas.clipPath(clipPath);
          } else {
            // One clip path with rect per shape path.
            for (final path in shape.paths) {
              var clipPath = ui.Path();
              clipPath.addRect(artboardRect);
              clipPath.addPath((path as FlutterPath).path, ui.Offset.zero,
                  matrix4: path.pathTransform?.mat4);
              clipPath.fillType = PathFillType.evenOdd;
              canvas.clipPath(clipPath);
            }
          }
        }
      }
    }
  }
}

abstract class FlutterFill {
  ui.Paint _paint;

  void onPaintUpdated(ui.Paint paint) {}

  void initializeGraphics() {
    _paint = ui.Paint()..style = PaintingStyle.fill;
    onPaintUpdated(_paint);
  }

  void paint(ActorFill fill, ui.Canvas canvas, ui.Path path) {
    switch (fill.fillRule) {
      case FillRule.evenOdd:
        path.fillType = ui.PathFillType.evenOdd;
        break;
      case FillRule.nonZero:
        path.fillType = ui.PathFillType.nonZero;
        break;
    }
    canvas.drawPath(path, _paint);
  }
}

abstract class FlutterStroke {
  ui.Paint _paint;
  void onPaintUpdated(ui.Paint paint) {}
  ui.Path effectPath;

  void initializeGraphics() {
    // yikes, no nice way to inherit with a mixin.
    ActorStroke stroke = this as ActorStroke;

    _paint = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = stroke.width
      ..strokeCap = FlutterStroke.getStrokeCap(stroke.cap)
      ..strokeJoin = FlutterStroke.getStrokeJoin(stroke.join);
    onPaintUpdated(_paint);
  }

  static ui.StrokeCap getStrokeCap(StrokeCap cap) {
    switch (cap) {
      case StrokeCap.butt:
        return ui.StrokeCap.butt;
      case StrokeCap.round:
        return ui.StrokeCap.round;
      case StrokeCap.square:
        return ui.StrokeCap.square;
    }
    return ui.StrokeCap.butt;
  }

  static ui.StrokeJoin getStrokeJoin(StrokeJoin join) {
    switch (join) {
      case StrokeJoin.miter:
        return ui.StrokeJoin.miter;
      case StrokeJoin.round:
        return ui.StrokeJoin.round;
      case StrokeJoin.bevel:
        return ui.StrokeJoin.bevel;
    }
    return ui.StrokeJoin.miter;
  }

  void paint(ActorStroke stroke, ui.Canvas canvas, ui.Path path) {
    if (stroke.width == 0) {
      return;
    }

    if (stroke.isTrimmed) {
      if (effectPath == null) {
        bool isSequential = stroke.trim == TrimPath.sequential;
        double start = stroke.trimStart.clamp(0, 1).toDouble();
        double end = stroke.trimEnd.clamp(0, 1).toDouble();
        double offset = stroke.trimOffset;
        bool inverted = start > end;
        if ((start - end).abs() != 1.0) {
          start = (start + offset) % 1.0;
          end = (end + offset) % 1.0;

          if (start < 0) {
            start += 1.0;
          }
          if (end < 0) {
            end += 1.0;
          }
          if (inverted) {
            final double swap = end;
            end = start;
            start = swap;
          }
          if (end >= start) {
            effectPath = trimPath(path, start, end, false, isSequential);
          } else {
            effectPath = trimPath(path, end, start, true, isSequential);
          }
        } else {
          effectPath = path;
        }
      }
      path = effectPath;
    }
    canvas.drawPath(path, _paint);
  }

  void markPathEffectsDirty() {
    effectPath = null;
  }
}

class FlutterActorShape extends ActorShape with FlutterActorDrawable {
  ui.Path _path;
  bool _isValid = false;

  @override
  void initializeGraphics() {
    super.initializeGraphics();
    _path = ui.Path();
    for (final ActorBasePath path in paths) {
      (path as FlutterPath).initializeGraphics();
    }
  }

  @override
  void invalidateShape() {
    _isValid = false;
    stroke?.markPathEffectsDirty();
  }

  @override
  void onBlendModeChanged(ui.BlendMode mode) {
    if (fills != null) {
      for (final ActorFill actorFill in fills) {
        (actorFill as ActorPaint).markPaintDirty();
      }
    }
    if (strokes != null) {
      for (final ActorStroke actorStroke in strokes) {
        (actorStroke as ActorPaint).markPaintDirty();
      }
    }
  }

  ui.Path get path {
    if (_isValid) {
      return _path;
    }
    _isValid = true;
    _path.reset();

    if (fill != null && fill.fillRule == FillRule.evenOdd) {
      _path.fillType = PathFillType.evenOdd;
    } else {
      _path.fillType = PathFillType.nonZero;
    }

    for (final ActorBasePath path in paths) {
      Mat2D transform = path.pathTransform;
      _path.addPath((path as FlutterPath).path, ui.Offset.zero,
          matrix4: transform?.mat4);
    }
    return _path;
  }

  ui.Path getRenderPath(ui.Canvas canvas) {
    return path;
  }

  @override
  void draw(ui.Canvas canvas) {
    if (!doesDraw) {
      return;
    }

    canvas.save();

    clip(canvas);

    ui.Path renderPath = getRenderPath(canvas);

    if (fills != null) {
      for (final ActorFill actorFill in fills) {
        FlutterFill fill = actorFill as FlutterFill;
        fill.paint(actorFill, canvas, renderPath);
      }
    }
    if (strokes != null) {
      for (final ActorStroke actorStroke in strokes) {
        FlutterStroke stroke = actorStroke as FlutterStroke;
        stroke.paint(actorStroke, canvas, renderPath);
      }
    }

    canvas.restore();
  }
}

class FlutterActorShapeWithTransformedStroke extends FlutterActorShape {
  ui.Path _localPath;
  bool _isLocalValid = false;

  @override
  void initializeGraphics() {
    super.initializeGraphics();
    _localPath = ui.Path();
  }

  @override
  void invalidateShape() {
    _isLocalValid = false;
    super.invalidateShape();
  }

  ui.Path get localPath {
    if (_isLocalValid) {
      return _localPath;
    }
    _isLocalValid = true;
    _localPath.reset();

    Mat2D inverseWorld = Mat2D();
    if (!Mat2D.invert(inverseWorld, worldTransform)) {
      Mat2D.identity(inverseWorld);
    }

    for (final ActorBasePath path in paths) {
      Mat2D transform = path.pathTransform;

      Mat2D localTransform;
      if (transform != null) {
        localTransform = Mat2D();
        Mat2D.multiply(localTransform, inverseWorld, transform);
      }
      _localPath.addPath((path as FlutterPath).path, ui.Offset.zero,
          matrix4: localTransform?.mat4);
    }
    return _localPath;
  }

  @override
  ui.Path getRenderPath(ui.Canvas canvas) {
    canvas.transform(worldTransform.mat4);
    return localPath;
  }
}

class FlutterColorFill extends ColorFill with FlutterFill {
  @override
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    FlutterColorFill instanceNode = FlutterColorFill();
    instanceNode.copyColorFill(this, resetArtboard);
    return instanceNode;
  }

  Color get uiColor {
    Float32List c = displayColor;
    double o = (artboard.modulateOpacity * opacity * shape.renderOpacity)
        .clamp(0.0, 1.0)
        .toDouble();
    return Color.fromRGBO((c[0] * 255.0).round(), (c[1] * 255.0).round(),
        (c[2] * 255.0).round(), c[3] * o);
  }

  set uiColor(Color c) {
    color = Float32List.fromList(
        [c.red / 255, c.green / 255, c.blue / 255, c.opacity]);
  }

  @override
  void update(int dirt) {
    super.update(dirt);
    _paint
      ..color = uiColor
      ..blendMode = (parent as FlutterActorShape).blendMode;
    onPaintUpdated(_paint);
  }
}

class FlutterColorStroke extends ColorStroke with FlutterStroke {
  @override
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    FlutterColorStroke instanceNode = FlutterColorStroke();
    instanceNode.copyColorStroke(this, resetArtboard);
    return instanceNode;
  }

  Color get uiColor {
    Float32List c = displayColor;
    double o = (artboard.modulateOpacity * opacity * shape.renderOpacity)
        .clamp(0.0, 1.0)
        .toDouble();
    return Color.fromRGBO((c[0] * 255.0).round(), (c[1] * 255.0).round(),
        (c[2] * 255.0).round(), c[3] * o);
  }

  set uiColor(Color c) {
    color = Float32List.fromList(
        [c.red / 255, c.green / 255, c.blue / 255, c.opacity]);
  }

  @override
  void update(int dirt) {
    super.update(dirt);
    _paint
      ..color = uiColor
      ..strokeWidth = width
      ..blendMode = (parent as FlutterActorShape).blendMode;
    onPaintUpdated(_paint);
  }
}

class FlutterGradientFill extends GradientFill with FlutterFill {
  @override
  void update(int dirt) {
    super.update(dirt);
    List<ui.Color> colors = <ui.Color>[];
    List<double> stops = <double>[];
    int numStops = (colorStops.length / 5).round();

    int idx = 0;
    for (int i = 0; i < numStops; i++) {
      double o = colorStops[idx + 3].clamp(0.0, 1.0).toDouble();
      ui.Color color = ui.Color.fromRGBO(
          (colorStops[idx] * 255.0).round(),
          (colorStops[idx + 1] * 255.0).round(),
          (colorStops[idx + 2] * 255.0).round(),
          o);
      colors.add(color);
      stops.add(colorStops[idx + 4]);
      idx += 5;
    }

    Color paintColor;
    if (artboard.overrideColor == null) {
      paintColor = Colors.white.withOpacity(
          (artboard.modulateOpacity * opacity * shape.renderOpacity)
              .clamp(0.0, 1.0)
              .toDouble());
    } else {
      Float32List overrideColor = artboard.overrideColor;
      double o = (overrideColor[3] *
              artboard.modulateOpacity *
              opacity *
              shape.renderOpacity)
          .clamp(0.0, 1.0)
          .toDouble();
      paintColor = ui.Color.fromRGBO(
          (overrideColor[0] * 255.0).round(),
          (overrideColor[1] * 255.0).round(),
          (overrideColor[2] * 255.0).round(),
          o);
    }
    _paint
      ..color = paintColor
      ..blendMode = (parent as FlutterActorShape).blendMode
      ..shader = ui.Gradient.linear(ui.Offset(renderStart[0], renderStart[1]),
          ui.Offset(renderEnd[0], renderEnd[1]), colors, stops);
    onPaintUpdated(_paint);
  }

  @override
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    FlutterGradientFill instanceNode = FlutterGradientFill();
    instanceNode.copyGradientFill(this, resetArtboard);
    return instanceNode;
  }
}

class FlutterGradientStroke extends GradientStroke with FlutterStroke {
  @override
  void update(int dirt) {
    super.update(dirt);
    List<ui.Color> colors = <ui.Color>[];
    List<double> stops = <double>[];
    int numStops = (colorStops.length / 5).round();

    int idx = 0;
    for (int i = 0; i < numStops; i++) {
      double o = colorStops[idx + 3].clamp(0.0, 1.0).toDouble();
      ui.Color color = ui.Color.fromRGBO(
          (colorStops[idx] * 255.0).round(),
          (colorStops[idx + 1] * 255.0).round(),
          (colorStops[idx + 2] * 255.0).round(),
          o);
      colors.add(color);
      stops.add(colorStops[idx + 4]);
      idx += 5;
    }

    Color paintColor;
    if (artboard.overrideColor == null) {
      paintColor = Colors.white.withOpacity(
          (artboard.modulateOpacity * opacity * shape.renderOpacity)
              .clamp(0.0, 1.0)
              .toDouble());
    } else {
      Float32List overrideColor = artboard.overrideColor;
      double o = (overrideColor[3] *
              artboard.modulateOpacity *
              opacity *
              shape.renderOpacity)
          .clamp(0.0, 1.0)
          .toDouble();
      paintColor = ui.Color.fromRGBO(
          (overrideColor[0] * 255.0).round(),
          (overrideColor[1] * 255.0).round(),
          (overrideColor[2] * 255.0).round(),
          o);
    }
    _paint
      ..color = paintColor
      ..blendMode = (parent as FlutterActorShape).blendMode
      ..strokeWidth = width
      ..shader = ui.Gradient.linear(ui.Offset(renderStart[0], renderStart[1]),
          ui.Offset(renderEnd[0], renderEnd[1]), colors, stops);
    onPaintUpdated(_paint);
  }

  @override
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    FlutterGradientStroke instanceNode = FlutterGradientStroke();
    instanceNode.copyGradientStroke(this, resetArtboard);
    return instanceNode;
  }
}

class FlutterRadialFill extends RadialGradientFill with FlutterFill {
  @override
  void update(int dirt) {
    super.update(dirt);
    double radius = Vec2D.distance(renderStart, renderEnd);
    List<ui.Color> colors = <ui.Color>[];
    List<double> stops = <double>[];
    int numStops = (colorStops.length / 5).round();

    int idx = 0;
    for (int i = 0; i < numStops; i++) {
      double o = colorStops[idx + 3].clamp(0.0, 1.0).toDouble();
      ui.Color color = ui.Color.fromRGBO(
          (colorStops[idx] * 255.0).round(),
          (colorStops[idx + 1] * 255.0).round(),
          (colorStops[idx + 2] * 255.0).round(),
          o);
      colors.add(color);
      stops.add(colorStops[idx + 4]);
      idx += 5;
    }
    ui.Gradient radial = ui.Gradient.radial(
        Offset(renderStart[0], renderStart[1]),
        radius,
        colors,
        stops,
        ui.TileMode.clamp);

    Color paintColor;
    if (artboard.overrideColor == null) {
      paintColor = Colors.white.withOpacity(
          (artboard.modulateOpacity * opacity * shape.renderOpacity)
              .clamp(0.0, 1.0)
              .toDouble());
    } else {
      Float32List overrideColor = artboard.overrideColor;
      double o = (overrideColor[3] *
              artboard.modulateOpacity *
              opacity *
              shape.renderOpacity)
          .clamp(0.0, 1.0)
          .toDouble();
      paintColor = ui.Color.fromRGBO(
          (overrideColor[0] * 255.0).round(),
          (overrideColor[1] * 255.0).round(),
          (overrideColor[2] * 255.0).round(),
          o);
    }

    _paint
      ..color = paintColor
      ..blendMode = (parent as FlutterActorShape).blendMode
      ..shader = radial;
    onPaintUpdated(_paint);
  }

  @override
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    FlutterRadialFill instanceNode = FlutterRadialFill();
    instanceNode.copyRadialFill(this, resetArtboard);
    return instanceNode;
  }
}

class FlutterRadialStroke extends RadialGradientStroke with FlutterStroke {
  @override
  void update(int dirt) {
    super.update(dirt);
    double radius = Vec2D.distance(renderStart, renderEnd);
    List<ui.Color> colors = <ui.Color>[];
    List<double> stops = <double>[];
    int numStops = (colorStops.length / 5).round();

    int idx = 0;
    for (int i = 0; i < numStops; i++) {
      double o = colorStops[idx + 3].clamp(0.0, 1.0).toDouble();
      ui.Color color = ui.Color.fromRGBO(
          (colorStops[idx] * 255.0).round(),
          (colorStops[idx + 1] * 255.0).round(),
          (colorStops[idx + 2] * 255.0).round(),
          o);
      colors.add(color);
      stops.add(colorStops[idx + 4]);
      idx += 5;
    }

    Color paintColor;
    if (artboard.overrideColor == null) {
      paintColor = Colors.white.withOpacity(
          (artboard.modulateOpacity * opacity * shape.renderOpacity)
              .clamp(0.0, 1.0)
              .toDouble());
    } else {
      Float32List overrideColor = artboard.overrideColor;
      double o = (overrideColor[3] *
              artboard.modulateOpacity *
              opacity *
              shape.renderOpacity)
          .clamp(0.0, 1.0)
          .toDouble();
      paintColor = ui.Color.fromRGBO(
          (overrideColor[0] * 255.0).round(),
          (overrideColor[1] * 255.0).round(),
          (overrideColor[2] * 255.0).round(),
          o);
    }

    _paint
      ..color = paintColor
      ..strokeWidth = width
      ..blendMode = (parent as FlutterActorShape).blendMode
      ..shader = ui.Gradient.radial(Offset(renderStart[0], renderStart[1]),
          radius, colors, stops, ui.TileMode.clamp);
    onPaintUpdated(_paint);
  }

  @override
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    FlutterRadialStroke instanceNode = FlutterRadialStroke();
    instanceNode.copyRadialStroke(this, resetArtboard);
    return instanceNode;
  }
}

class AssetBundleContext {
  final String filename;
  final AssetBundle bundle;
  AssetBundleContext(this.bundle, this.filename);
}

class FlutterActor extends Actor {
  List<ui.Image> _images;

  List<ui.Image> get images {
    return _images;
  }

  @override
  ActorArtboard makeArtboard() {
    return FlutterActorArtboard(this);
  }

  @override
  ActorShape makeShapeNode(ActorShape source) {
    return source?.transformAffectsStroke ?? false
        ? FlutterActorShapeWithTransformedStroke()
        : FlutterActorShape();
  }

  @override
  ActorPath makePathNode() {
    return FlutterActorPath();
  }

  @override
  ActorImage makeImageNode() {
    return FlutterActorImage();
  }

  @override
  ActorRectangle makeRectangle() {
    return FlutterActorRectangle();
  }

  @override
  ActorTriangle makeTriangle() {
    return FlutterActorTriangle();
  }

  @override
  ActorStar makeStar() {
    return FlutterActorStar();
  }

  @override
  ActorPolygon makePolygon() {
    return FlutterActorPolygon();
  }

  @override
  ActorEllipse makeEllipse() {
    return FlutterActorEllipse();
  }

  @override
  ColorFill makeColorFill() {
    return FlutterColorFill();
  }

  @override
  ColorStroke makeColorStroke() {
    return FlutterColorStroke();
  }

  @override
  GradientFill makeGradientFill() {
    return FlutterGradientFill();
  }

  @override
  GradientStroke makeGradientStroke() {
    return FlutterGradientStroke();
  }

  @override
  RadialGradientFill makeRadialFill() {
    return FlutterRadialFill();
  }

  @override
  RadialGradientStroke makeRadialStroke() {
    return FlutterRadialStroke();
  }

  @override
  ActorDropShadow makeDropShadow() {
    return FlutterActorDropShadow();
  }

  @override
  ActorLayerEffectRenderer makeLayerEffectRenderer() {
    return FlutterActorLayerEffectRenderer();
  }

  @override
  ActorInnerShadow makeInnerShadow() {
    return FlutterActorInnerShadow();
  }

  static Future<FlutterActor> loadFromByteData(ByteData data) async {
    //ByteData data = await context.bundle.load(context.filename);
    FlutterActor actor = FlutterActor();
    await actor.load(data, null);
    return actor;
  }

  Future<bool> loadFromBundle(AssetBundle assetBundle, String filename) async {
    ByteData data = await assetBundle.load(filename);
    return super.load(data, AssetBundleContext(assetBundle, filename));
  }

  void copyFlutterActor(FlutterActor actor) {
    copyActor(actor);
    _images = actor._images;
  }

  void dispose() {}

  List<Uint8List> _rawAtlasData;
  @override
  Future<bool> loadAtlases(List<Uint8List> rawAtlases) async {
    _rawAtlasData = rawAtlases;
    return true;
  }

  Future<bool> loadImages() async {
    if (_rawAtlasData == null) {
      return false;
    }
    List<Uint8List> data = _rawAtlasData;
    _rawAtlasData = null;
    List<ui.Codec> codecs =
        await Future.wait(data.map(ui.instantiateImageCodec));
    List<ui.FrameInfo> frames =
        await Future.wait(codecs.map((ui.Codec codec) => codec.getNextFrame()));
    _images =
        frames.map((ui.FrameInfo frame) => frame.image).toList(growable: false);
    return true;
  }

  @override
  Future<Uint8List> readOutOfBandAsset(
      String assetFilename, dynamic context) async {
    AssetBundleContext bundleContext = context as AssetBundleContext;
    int pathIdx = bundleContext.filename.lastIndexOf('/') + 1;
    String basePath = bundleContext.filename.substring(0, pathIdx);
    ByteData data = await bundleContext.bundle.load(basePath + assetFilename);
    return Uint8List.view(data.buffer);
  }
}

class FlutterActorArtboard extends ActorArtboard {
  FlutterActorArtboard(FlutterActor actor) : super(actor);

  void draw(ui.Canvas canvas) {
    if (clipContents) {
      canvas.save();
      AABB aabb = artboardAABB();
      canvas.clipRect(Rect.fromLTRB(aabb[0], aabb[1], aabb[2], aabb[3]));
    }
    if (drawableNodes != null) {
      for (final ActorDrawable drawable in drawableNodes) {
        if (drawable is FlutterActorDrawable) {
          (drawable as FlutterActorDrawable).draw(canvas);
        }
      }
    }
    if (clipContents) {
      canvas.restore();
    }
  }

  void dispose() {}
}

class FlutterActorPath extends ActorPath with FlutterPathPointsPath {
  @override
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    FlutterActorPath instanceNode = FlutterActorPath();
    instanceNode.copyPath(this, resetArtboard);
    return instanceNode;
  }
}

class FlutterActorEllipse extends ActorEllipse with FlutterPathPointsPath {
  @override
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    FlutterActorEllipse instanceNode = FlutterActorEllipse();
    instanceNode.copyPath(this, resetArtboard);
    return instanceNode;
  }
}

class FlutterActorPolygon extends ActorPolygon with FlutterPathPointsPath {
  @override
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    FlutterActorPolygon instanceNode = FlutterActorPolygon();
    instanceNode.copyPolygon(this, resetArtboard);
    return instanceNode;
  }
}

class FlutterActorStar extends ActorStar with FlutterPathPointsPath {
  @override
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    FlutterActorStar instanceNode = FlutterActorStar();
    instanceNode.copyStar(this, resetArtboard);
    return instanceNode;
  }
}

class FlutterActorRectangle extends ActorRectangle with FlutterPathPointsPath {
  @override
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    FlutterActorRectangle instanceNode = FlutterActorRectangle();
    instanceNode.copyRectangle(this, resetArtboard);
    return instanceNode;
  }
}

class FlutterActorTriangle extends ActorTriangle with FlutterPathPointsPath {
  @override
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    FlutterActorTriangle instanceNode = FlutterActorTriangle();
    instanceNode.copyPath(this, resetArtboard);
    return instanceNode;
  }
}

/// Abstract base path that can be invalidated and somehow
/// regenerates, no concrete logic
abstract class FlutterPath {
  ui.Path get path;
  void initializeGraphics();
}

/// Abstract path that uses Actor PathPoints, slightly higher level
/// that FlutterPath. Most shapes can use this, but if they want to
/// use a different procedural backing call, they should implement
/// FlutterPath and generate the path another way.
abstract class FlutterPathPointsPath implements FlutterPath {
  ui.Path _path;
  List<PathPoint> get deformedPoints;
  bool get isClosed;
  bool _isValid = false;

  @override
  void initializeGraphics() {
    _path = ui.Path();
  }

  @override
  ui.Path get path {
    if (_isValid) {
      return _path;
    }
    return _makePath();
  }

  void invalidatePath() {
    _isValid = false;
  }

  ui.Path _makePath() {
    _isValid = true;
    _path.reset();
    List<PathPoint> pts = deformedPoints;
    if (pts == null || pts.isEmpty) {
      return _path;
    }

    List<PathPoint> renderPoints = [];
    int pl = pts.length;

    const double arcConstant = 0.55;
    const double iarcConstant = 1.0 - arcConstant;
    PathPoint previous = isClosed ? pts[pl - 1] : null;
    for (int i = 0; i < pl; i++) {
      PathPoint point = pts[i];
      switch (point.pointType) {
        case PointType.straight:
          {
            StraightPathPoint straightPoint = point as StraightPathPoint;
            double radius = straightPoint.radius;
            if (radius > 0) {
              if (!isClosed && (i == 0 || i == pl - 1)) {
                renderPoints.add(point);
                previous = point;
              } else {
                PathPoint next = pts[(i + 1) % pl];
                Vec2D prevPoint = previous is CubicPathPoint
                    ? previous.outPoint
                    : previous.translation;
                Vec2D nextPoint =
                    next is CubicPathPoint ? next.inPoint : next.translation;
                Vec2D pos = point.translation;

                Vec2D toPrev = Vec2D.subtract(Vec2D(), prevPoint, pos);
                double toPrevLength = Vec2D.length(toPrev);
                toPrev[0] /= toPrevLength;
                toPrev[1] /= toPrevLength;

                Vec2D toNext = Vec2D.subtract(Vec2D(), nextPoint, pos);
                double toNextLength = Vec2D.length(toNext);
                toNext[0] /= toNextLength;
                toNext[1] /= toNextLength;

                double renderRadius =
                    min(toPrevLength, min(toNextLength, radius));

                Vec2D translation =
                    Vec2D.scaleAndAdd(Vec2D(), pos, toPrev, renderRadius);
                renderPoints.add(CubicPathPoint.fromValues(
                    translation,
                    translation,
                    Vec2D.scaleAndAdd(
                        Vec2D(), pos, toPrev, iarcConstant * renderRadius)));
                translation =
                    Vec2D.scaleAndAdd(Vec2D(), pos, toNext, renderRadius);
                previous = CubicPathPoint.fromValues(
                    translation,
                    Vec2D.scaleAndAdd(
                        Vec2D(), pos, toNext, iarcConstant * renderRadius),
                    translation);
                renderPoints.add(previous);
              }
            } else {
              renderPoints.add(point);
              previous = point;
            }
            break;
          }
        default:
          renderPoints.add(point);
          previous = point;
          break;
      }
    }

    PathPoint firstPoint = renderPoints[0];
    _path.moveTo(firstPoint.translation[0], firstPoint.translation[1]);
    for (int i = 0,
            l = isClosed ? renderPoints.length : renderPoints.length - 1,
            pl = renderPoints.length;
        i < l;
        i++) {
      PathPoint point = renderPoints[i];
      PathPoint nextPoint = renderPoints[(i + 1) % pl];
      Vec2D cin = nextPoint is CubicPathPoint ? nextPoint.inPoint : null;
      Vec2D cout = point is CubicPathPoint ? point.outPoint : null;
      if (cin == null && cout == null) {
        _path.lineTo(nextPoint.translation[0], nextPoint.translation[1]);
      } else {
        cout ??= point.translation;
        cin ??= nextPoint.translation;

        _path.cubicTo(cout[0], cout[1], cin[0], cin[1],
            nextPoint.translation[0], nextPoint.translation[1]);
      }
    }

    if (isClosed) {
      _path.close();
    }

    return _path;
  }
}

class FlutterActorImage extends ActorImage with FlutterActorDrawable {
  Float32List _vertexBuffer;
  Float32List _uvBuffer;
  ui.Paint _paint;
  ui.Vertices _canvasVertices;
  Uint16List _indices;

  void onPaintUpdated(ui.Paint paint) {}
  final Float64List _identityMatrix = Float64List.fromList(<double>[
    1.0,
    0.0,
    0.0,
    0.0,
    0.0,
    1.0,
    0.0,
    0.0,
    0.0,
    0.0,
    1.0,
    0.0,
    0.0,
    0.0,
    0.0,
    1.0
  ]);

  set textureIndex(int value) {
    if (textureIndex != value) {
      List<ui.Image> images = (artboard.actor as FlutterActor).images;
      _paint = ui.Paint()
        ..blendMode = blendMode
        ..shader = images != null
            ? ui.ImageShader(images[textureIndex], ui.TileMode.clamp,
                ui.TileMode.clamp, _identityMatrix)
            : null
        ..filterQuality = ui.FilterQuality.low
        ..isAntiAlias = true;
      onPaintUpdated(_paint);
    }
  }

  void dispose() {
    _uvBuffer = null;
    _vertexBuffer = null;
    _indices = null;
    _paint = null;
  }

  @override
  void onBlendModeChanged(ui.BlendMode mode) {
    if (_paint != null) {
      _paint.blendMode = mode;
      onPaintUpdated(_paint);
    }
  }

  /// Swap the image used to draw the mesh for this image node.
  /// Returns true when successful.
  bool changeImage(ui.Image image) {
    if (triangles == null || dynamicUV == null) {
      return false;
    }
    _uvBuffer = makeVertexUVBuffer();
    int count = vertexCount;

    // SKIA requires texture coordinates in full image space, not traditional
    // normalized uv coordinates.
    int idx = 0;
    for (int i = 0; i < count; i++) {
      _uvBuffer[idx] = dynamicUV[idx] * image.width;
      _uvBuffer[idx + 1] = dynamicUV[idx + 1] * image.height;
      idx += 2;
    }

    _paint.shader = image != null
        ? ui.ImageShader(
            image, ui.TileMode.clamp, ui.TileMode.clamp, _identityMatrix)
        : null;

    _canvasVertices = ui.Vertices.raw(ui.VertexMode.triangles, _vertexBuffer,
        indices: _indices, textureCoordinates: _uvBuffer);

    onPaintUpdated(_paint);

    return true;
  }

  /// Change the image for this node via a network url.
  /// Returns true when successful.
  /// TODO: re-enable this when the changes to instantiateImageCodec
  ///  land in stable.
//   Future<bool> changeImageFromNetwork(String url) async {
//     var networkImage = NetworkImage(url);
//     var val = await networkImage.obtainKey(const ImageConfiguration());
//     var load = networkImage.load(val, (Uint8List bytes,
//         {int cacheWidth, int cacheHeight}) {
//       return PaintingBinding.instance.instantiateImageCodec(bytes,
//           cacheWidth: cacheWidth, cacheHeight: cacheHeight);
//     });

//     final completer = Completer<bool>();
//     load.addListener(ImageStreamListener((ImageInfo info, bool syncCall) {
//       changeImage(info.image);
//       completer.complete(true);
//     }));
//     return completer.future;
//   }

  /// Change the image for this node with one in an asset bundle.
  /// Returns true when successful.
  Future<bool> changeImageFromBundle(
      AssetBundle bundle, String filename) async {
    ByteData data = await bundle.load(filename);
    ui.Codec codec =
        await ui.instantiateImageCodec(Uint8List.view(data.buffer));
    ui.FrameInfo frame = await codec.getNextFrame();
    return changeImage(frame.image);
  }

  @override
  void initializeGraphics() {
    super.initializeGraphics();
    if (triangles == null) {
      return;
    }
    _vertexBuffer = makeVertexPositionBuffer();
    _uvBuffer = makeVertexUVBuffer();
    _indices = triangles;
    updateVertexUVBuffer(_uvBuffer);
    int count = vertexCount;
    int idx = 0;
    List<ui.Image> images = (artboard.actor as FlutterActor).images;
    ui.Image image;
    if (images != null) {
      image = (artboard.actor as FlutterActor).images[textureIndex];

      // SKIA requires texture coordinates in full image space, not traditional
      // normalized uv coordinates.
      for (int i = 0; i < count; i++) {
        _uvBuffer[idx] = _uvBuffer[idx] * image.width;
        _uvBuffer[idx + 1] = _uvBuffer[idx + 1] * image.height;
        idx += 2;
      }

      if (sequenceUVs != null) {
        for (int i = 0; i < sequenceUVs.length; i++) {
          sequenceUVs[i++] *= image.width;
          sequenceUVs[i] *= image.height;
        }
      }
    }

    _paint = ui.Paint()
      ..blendMode = blendMode
      ..shader = image != null
          ? ui.ImageShader(
              image, ui.TileMode.clamp, ui.TileMode.clamp, _identityMatrix)
          : null;
    _paint.filterQuality = ui.FilterQuality.low;
    _paint.isAntiAlias = true;
    onPaintUpdated(_paint);
  }

  @override
  void invalidateDrawable() {
    _canvasVertices = null;
  }

  bool updateVertices() {
    if (triangles == null) {
      return false;
    }
    updateVertexPositionBuffer(_vertexBuffer, false);

    _canvasVertices = ui.Vertices.raw(ui.VertexMode.triangles, _vertexBuffer,
        indices: _indices, textureCoordinates: _uvBuffer);
    return true;
  }

  @override
  void draw(ui.Canvas canvas) {
    if (triangles == null || renderCollapsed || renderOpacity <= 0) {
      return;
    }

    if (_canvasVertices == null && !updateVertices()) {
      return;
    }
    canvas.save();

    clip(canvas);
    _paint.color =
        _paint.color.withOpacity(renderOpacity.clamp(0.0, 1.0).toDouble());

    if (imageTransform != null) {
      canvas.transform(imageTransform.mat4);
      canvas.drawVertices(_canvasVertices, ui.BlendMode.srcOver, _paint);
    } else {
      canvas.drawVertices(_canvasVertices, ui.BlendMode.srcOver, _paint);
    }

    canvas.restore();
  }

  @override
  AABB computeAABB() {
    updateVertices();

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    int readIdx = 0;
    if (_vertexBuffer != null) {
      int nv = _vertexBuffer.length ~/ 2;

      for (int i = 0; i < nv; i++) {
        double x = _vertexBuffer[readIdx++];
        double y = _vertexBuffer[readIdx++];
        if (x < minX) {
          minX = x;
        }
        if (y < minY) {
          minY = y;
        }
        if (x > maxX) {
          maxX = x;
        }
        if (y > maxY) {
          maxY = y;
        }
      }
    }

    return AABB.fromValues(minX, minY, maxX, maxY);
  }

  @override
  void update(int dirt) {
    super.update(dirt);
    if (dirt & DirtyFlags.paintDirty != 0) {
      onPaintUpdated(_paint);
    }
  }
}

class FlutterActorDropShadow extends ActorDropShadow {
  @override
  int get blendModeId {
    return blendMode.index;
  }

  @override
  set blendModeId(int index) {
    blendMode = ui.BlendMode.values[index];
  }

  ui.BlendMode blendMode;
}

class FlutterActorInnerShadow extends ActorInnerShadow {
  @override
  int get blendModeId {
    return blendMode.index;
  }

  @override
  set blendModeId(int index) {
    blendMode = ui.BlendMode.values[index];
  }

  ui.BlendMode blendMode;
}

ui.ImageFilter _blurFilter(double x, double y) {
  double bx = x.abs() < 0.1 ? 0 : x;
  double by = y.abs() < 0.1 ? 0 : y;
  return bx == 0 && by == 0
      ? null
      : ui.ImageFilter.blur(sigmaX: bx, sigmaY: by);
}

class FlutterActorLayerEffectRenderer extends ActorLayerEffectRenderer
    with FlutterActorDrawable {
  @override
  void draw(ui.Canvas canvas) {
    var aabb = artboard.artboardAABB();
    Rect bounds = Rect.fromLTRB(aabb[0], aabb[1], aabb[2], aabb[3]);

    double baseBlurX = 0;
    double baseBlurY = 0;
    Paint layerPaint = Paint();
    Color layerColor = Colors.white.withOpacity(parent.renderOpacity);
    layerPaint.color = layerColor;
    if (blur?.isActive ?? false) {
      baseBlurX = blur.blurX;
      baseBlurY = blur.blurY;
      layerPaint.imageFilter = _blurFilter(baseBlurX, baseBlurY);
    }

    if (dropShadows.isNotEmpty) {
      for (final dropShadow in dropShadows) {
        if (!dropShadow.isActive) {
          continue;
        }
        // DropShadow: To draw a shadow we just draw the shape (with
        // drawPass) with a custom color and image (blur) filter before
        // drawing the main shape.
        canvas.save();
        var color = dropShadow.color;
        canvas.translate(dropShadow.offsetX, dropShadow.offsetY);
        var shadowPaint = Paint()
          ..color = layerColor
          ..imageFilter = _blurFilter(
              dropShadow.blurX + baseBlurX, dropShadow.blurY + baseBlurY)
          ..colorFilter = ui.ColorFilter.mode(
              ui.Color.fromRGBO(
                  (color[0] * 255.0).round(),
                  (color[1] * 255.0).round(),
                  (color[2] * 255.0).round(),
                  color[3]),
              ui.BlendMode.srcIn)
          ..blendMode = ui.BlendMode.values[dropShadow.blendModeId];

        drawPass(canvas, bounds, shadowPaint);
        canvas.restore();
        canvas.restore();
      }
    }
    drawPass(canvas, bounds, layerPaint);
    // Draw inner shadows on the main layer.
    if (innerShadows.isNotEmpty) {
      for (final innerShadow in innerShadows) {
        if (!innerShadow.isActive) {
          continue;
        }
        var blendMode = ui.BlendMode.values[innerShadow.blendModeId];
        bool extraBlendPass = blendMode != ui.BlendMode.srcOver;
        if (extraBlendPass) {
          // if we have a custom blend mode, then we can't just srcATop with
          // what's already been drawn. We need to draw the contents as a mask
          // to then draw the shadow on top of with srcIn to only show the
          // shadow and finally composite with the desired blend mode requested
          // here.
          var extraLayerPaint = Paint()..blendMode = blendMode;
          drawPass(canvas, bounds, extraLayerPaint);
        }

        // because there's no way to compose image filters (use two filters in
        // one) we have to use an extra layer to invert the alpha for the inner
        // shadow before blurring.

        var color = innerShadow.color;
        var shadowPaint = Paint()
          ..color = layerColor
          ..blendMode =
              extraBlendPass ? ui.BlendMode.srcIn : ui.BlendMode.srcATop
          ..imageFilter = _blurFilter(
              innerShadow.blurX + baseBlurX, innerShadow.blurY + baseBlurY)
          ..colorFilter = ui.ColorFilter.mode(
              ui.Color.fromRGBO(
                  (color[0] * 255.0).round(),
                  (color[1] * 255.0).round(),
                  (color[2] * 255.0).round(),
                  color[3]),
              ui.BlendMode.srcIn);

        canvas.saveLayer(bounds, shadowPaint);
        canvas.translate(innerShadow.offsetX, innerShadow.offsetY);

        // Invert the alpha to compute inner part.
        var invertPaint = Paint()
          ..colorFilter = const ui.ColorFilter.matrix([
            1,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
            0,
            0,
            0,
            0,
            -1,
            255,
          ]);
        drawPass(canvas, bounds, invertPaint);
        // restore draw pass (inverted aint)
        canvas.restore();
        // restore save layer used to that blurs and colors the shadow
        canvas.restore();

        if (extraBlendPass) {
          // Restore extra layer used to draw the contents to clip against (we
          // clip by drawing with srcIn)
          canvas.restore();
        }
      }
    }
    canvas.restore();
  }

  void drawPass(ui.Canvas canvas, Rect bounds, Paint layerPaint) {
    canvas.saveLayer(bounds, layerPaint);
    for (final drawable in drawables) {
      if (drawable is FlutterActorDrawable) {
        (drawable as FlutterActorDrawable).draw(canvas);
      }
    }

    for (final renderMask in renderMasks) {
      var mask = renderMask.mask;
      if (!mask.isActive) {
        continue;
      }

      var maskPaint = Paint();
      switch (mask.maskType) {
        case MaskType.invertedAlpha:
          maskPaint.colorFilter = const ui.ColorFilter.matrix(
              [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 255]);
          break;
        case MaskType.luminance:
          maskPaint.colorFilter = const ui.ColorFilter.matrix([
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0.33,
            0.59,
            0.11,
            0,
            0
          ]);
          break;
        case MaskType.invertedLuminance:
          maskPaint.colorFilter = const ui.ColorFilter.matrix([
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            -0.33,
            -0.59,
            -0.11,
            0,
            255
          ]);
          break;
        case MaskType.alpha:
        default:
          maskPaint.colorFilter = const ui.ColorFilter.matrix(
              [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0]);
          break;
      }

      maskPaint.blendMode = BlendMode.dstIn;
      canvas.saveLayer(bounds, maskPaint);
      for (final drawable in renderMask.drawables) {
        bool wasHidden = drawable.isHidden;
        if (wasHidden) {
          drawable.isHidden = false;
        }
        (drawable as FlutterActorDrawable).draw(canvas);
        if (wasHidden) {
          drawable.isHidden = true;
        }
      }
      canvas.restore();
    }
  }

  @override
  void onBlendModeChanged(ui.BlendMode blendMode) {
    // We don't currently support custom blend modes on the layer effect
    // renderer.
  }
}
