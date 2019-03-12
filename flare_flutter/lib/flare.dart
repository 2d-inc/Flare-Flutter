library flare_flutter;

import 'dart:ui' as ui;
import 'dart:math';
import 'package:flare_dart/actor_image.dart';
import 'package:flare_dart/math/aabb.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:typed_data';
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
import 'package:flare_dart/actor_node.dart';
import 'package:flare_dart/actor_drawable.dart';
import 'package:flare_dart/math/mat2d.dart';
import 'package:flare_dart/math/vec2d.dart';
import 'package:flare_dart/path_point.dart';
export 'package:flare_dart/animation/actor_animation.dart';
export 'package:flare_dart/actor_node.dart';
import 'trim_path.dart';

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
}

abstract class FlutterFill {
  ui.Paint _paint;
  void initializeGraphics() {
    _paint = ui.Paint()..style = PaintingStyle.fill;
  }

  void paint(ActorFill fill, ui.Canvas canvas, ui.Path path) {
    switch (fill.fillRule) {
      case FillRule.EvenOdd:
        path.fillType = ui.PathFillType.evenOdd;
        break;
      case FillRule.NonZero:
        path.fillType = ui.PathFillType.nonZero;
        break;
    }
    canvas.drawPath(path, _paint);
  }
}

abstract class FlutterStroke {
  ui.Paint _paint;
  ui.Path effectPath;

  void initializeGraphics() {
    // yikes, no nice way to inherit with a mixin.
    ActorStroke stroke = this as ActorStroke;

    _paint = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = stroke.width
      ..strokeCap = FlutterStroke.getStrokeCap(stroke.cap)
      ..strokeJoin = FlutterStroke.getStrokeJoin(stroke.join);
  }

  static ui.StrokeCap getStrokeCap(StrokeCap cap) {
    switch (cap) {
      case StrokeCap.Butt:
        return ui.StrokeCap.butt;
      case StrokeCap.Round:
        return ui.StrokeCap.round;
      case StrokeCap.Square:
        return ui.StrokeCap.square;
    }
    return ui.StrokeCap.butt;
  }

  static ui.StrokeJoin getStrokeJoin(StrokeJoin join) {
    switch (join) {
      case StrokeJoin.Miter:
        return ui.StrokeJoin.miter;
      case StrokeJoin.Round:
        return ui.StrokeJoin.round;
      case StrokeJoin.Bevel:
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
        bool isSequential = stroke.trim == TrimPath.Sequential;
        double start = stroke.trimStart;
        double end = stroke.trimEnd;
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
  ui.Path _path = ui.Path();
  bool _isValid = false;

  @override
  void invalidateShape() {
    _isValid = false;
    stroke?.markPathEffectsDirty();
  }

  @override
  void onBlendModeChanged(ui.BlendMode mode) {
    if (fills != null) {
      for (ActorFill actorFill in fills) {
        (actorFill as ActorPaint).markPaintDirty();
      }
    }
    if (strokes != null) {
      for (ActorStroke actorStroke in strokes) {
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

    if (children != null) {
      for (ActorNode node in children) {
        FlutterPath flutterPath = node as FlutterPath;
        if (flutterPath != null) {
          Mat2D transform = (node as ActorBasePath).pathTransform;
          _path.addPath(flutterPath.path, ui.Offset.zero,
              matrix4: transform == null ? null : transform.mat4);
        }
      }
    }
    return _path;
  }

  void draw(ui.Canvas canvas) {
    if (!this.doesDraw) {
      return;
    }

    canvas.save();

    ui.Path renderPath = path;

    // Get Clips
    for (List<ActorShape> clips in clipShapes) {
      if (clips.length == 1) {
        canvas.clipPath((clips[0] as FlutterActorShape).path);
      } else {
        ui.Path clippingPath = ui.Path();
        for (ActorShape clipShape in clips) {
          clippingPath.addPath(
              (clipShape as FlutterActorShape).path, ui.Offset.zero);
        }
        canvas.clipPath(clippingPath);
      }
    }
    if (fills != null) {
      for (ActorFill actorFill in fills) {
        FlutterFill fill = actorFill as FlutterFill;
        fill.paint(actorFill, canvas, renderPath);
      }
    }
    if (strokes != null) {
      for (ActorStroke actorStroke in strokes) {
        FlutterStroke stroke = actorStroke as FlutterStroke;
        stroke.paint(actorStroke, canvas, renderPath);
      }
    }

    canvas.restore();
  }

  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    FlutterActorShape instanceNode = FlutterActorShape();
    instanceNode.copyShape(this, resetArtboard);
    return instanceNode;
  }
}

class FlutterColorFill extends ColorFill with FlutterFill {
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    FlutterColorFill instanceNode = FlutterColorFill();
    instanceNode.copyColorFill(this, resetArtboard);
    return instanceNode;
  }

  Color get uiColor {
    Float32List c = displayColor;
    return Color.fromRGBO(
        (c[0] * 255.0).round(),
        (c[1] * 255.0).round(),
        (c[2] * 255.0).round(),
        c[3] * artboard.modulateOpacity * opacity * shape.renderOpacity);
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
  }
}

class FlutterColorStroke extends ColorStroke with FlutterStroke {
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    FlutterColorStroke instanceNode = FlutterColorStroke();
    instanceNode.copyColorStroke(this, resetArtboard);
    return instanceNode;
  }

  Color get uiColor {
    Float32List c = displayColor;
    return Color.fromRGBO(
        (c[0] * 255.0).round(),
        (c[1] * 255.0).round(),
        (c[2] * 255.0).round(),
        c[3] * artboard.modulateOpacity * opacity * shape.renderOpacity);
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
  }
}

class FlutterGradientFill extends GradientFill with FlutterFill {
  @override
  void update(int dirt) {
    super.update(dirt);
    List<ui.Color> colors = List<ui.Color>();
    List<double> stops = List<double>();
    int numStops = (colorStops.length / 5).round();

    int idx = 0;
    for (int i = 0; i < numStops; i++) {
      ui.Color color = ui.Color.fromRGBO(
          (colorStops[idx] * 255.0).round(),
          (colorStops[idx + 1] * 255.0).round(),
          (colorStops[idx + 2] * 255.0).round(),
          colorStops[idx + 3]);
      colors.add(color);
      stops.add(colorStops[idx + 4]);
      idx += 5;
    }

    Color paintColor;
    if (artboard.overrideColor == null) {
      paintColor = Colors.white.withOpacity(
          (artboard.modulateOpacity * opacity * shape.renderOpacity)
              .clamp(0.0, 1.0));
    } else {
      Float32List overrideColor = artboard.overrideColor;
      paintColor = ui.Color.fromRGBO(
          (overrideColor[0] * 255.0).round(),
          (overrideColor[1] * 255.0).round(),
          (overrideColor[2] * 255.0).round(),
          overrideColor[3] *
              artboard.modulateOpacity *
              opacity *
              shape.renderOpacity);
    }
    _paint
      ..color = paintColor
      ..blendMode = (parent as FlutterActorShape).blendMode
      ..shader = ui.Gradient.linear(ui.Offset(renderStart[0], renderStart[1]),
          ui.Offset(renderEnd[0], renderEnd[1]), colors, stops);
  }

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
    List<ui.Color> colors = List<ui.Color>();
    List<double> stops = List<double>();
    int numStops = (colorStops.length / 5).round();

    int idx = 0;
    for (int i = 0; i < numStops; i++) {
      ui.Color color = ui.Color.fromRGBO(
          (colorStops[idx] * 255.0).round(),
          (colorStops[idx + 1] * 255.0).round(),
          (colorStops[idx + 2] * 255.0).round(),
          colorStops[idx + 3]);
      colors.add(color);
      stops.add(colorStops[idx + 4]);
      idx += 5;
    }

    Color paintColor;
    if (artboard.overrideColor == null) {
      paintColor = Colors.white.withOpacity(
          (artboard.modulateOpacity * opacity * shape.renderOpacity)
              .clamp(0.0, 1.0));
    } else {
      Float32List overrideColor = artboard.overrideColor;
      paintColor = ui.Color.fromRGBO(
          (overrideColor[0] * 255.0).round(),
          (overrideColor[1] * 255.0).round(),
          (overrideColor[2] * 255.0).round(),
          overrideColor[3] *
              artboard.modulateOpacity *
              opacity *
              shape.renderOpacity);
    }
    _paint
      ..color = paintColor
      ..blendMode = (parent as FlutterActorShape).blendMode
      ..strokeWidth = width
      ..shader = ui.Gradient.linear(ui.Offset(renderStart[0], renderStart[1]),
          ui.Offset(renderEnd[0], renderEnd[1]), colors, stops);
  }

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
    List<ui.Color> colors = List<ui.Color>();
    List<double> stops = List<double>();
    int numStops = (colorStops.length / 5).round();

    int idx = 0;
    for (int i = 0; i < numStops; i++) {
      ui.Color color = ui.Color.fromRGBO(
          (colorStops[idx] * 255.0).round(),
          (colorStops[idx + 1] * 255.0).round(),
          (colorStops[idx + 2] * 255.0).round(),
          colorStops[idx + 3]);
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
              .clamp(0.0, 1.0));
    } else {
      Float32List overrideColor = artboard.overrideColor;
      paintColor = ui.Color.fromRGBO(
          (overrideColor[0] * 255.0).round(),
          (overrideColor[1] * 255.0).round(),
          (overrideColor[2] * 255.0).round(),
          overrideColor[3] *
              artboard.modulateOpacity *
              opacity *
              shape.renderOpacity);
    }

    _paint
      ..color = paintColor
      ..blendMode = (parent as FlutterActorShape).blendMode
      ..shader = radial;
  }

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
    List<ui.Color> colors = List<ui.Color>();
    List<double> stops = List<double>();
    int numStops = (colorStops.length / 5).round();

    int idx = 0;
    for (int i = 0; i < numStops; i++) {
      ui.Color color = ui.Color.fromRGBO(
          (colorStops[idx] * 255.0).round(),
          (colorStops[idx + 1] * 255.0).round(),
          (colorStops[idx + 2] * 255.0).round(),
          colorStops[idx + 3]);
      colors.add(color);
      stops.add(colorStops[idx + 4]);
      idx += 5;
    }

    Color paintColor;
    if (artboard.overrideColor == null) {
      paintColor = Colors.white.withOpacity(
          (artboard.modulateOpacity * opacity * shape.renderOpacity)
              .clamp(0.0, 1.0));
    } else {
      Float32List overrideColor = artboard.overrideColor;
      paintColor = ui.Color.fromRGBO(
          (overrideColor[0] * 255.0).round(),
          (overrideColor[1] * 255.0).round(),
          (overrideColor[2] * 255.0).round(),
          overrideColor[3] *
              artboard.modulateOpacity *
              opacity *
              shape.renderOpacity);
    }

    _paint
      ..color = paintColor
      ..strokeWidth = width
      ..blendMode = (parent as FlutterActorShape).blendMode
      ..shader = ui.Gradient.radial(Offset(renderStart[0], renderStart[1]),
          radius, colors, stops, ui.TileMode.clamp);
  }

  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    FlutterRadialStroke instanceNode = FlutterRadialStroke();
    instanceNode.copyRadialStroke(this, resetArtboard);
    return instanceNode;
  }
}

class _AssetBundleContext {
  String filename;
  AssetBundle bundle;
  _AssetBundleContext(filename, bundle);
}

class FlutterActor extends Actor {
  List<ui.Image> _images;

  List<ui.Image> get images {
    return _images;
  }

  ActorArtboard makeArtboard() {
    return FlutterActorArtboard(this);
  }

  ActorShape makeShapeNode() {
    return FlutterActorShape();
  }

  ActorPath makePathNode() {
    return FlutterActorPath();
  }

  ActorImage makeImageNode() {
    return FlutterActorImage();
  }

  ActorRectangle makeRectangle() {
    return FlutterActorRectangle();
  }

  ActorTriangle makeTriangle() {
    return FlutterActorTriangle();
  }

  ActorStar makeStar() {
    return FlutterActorStar();
  }

  ActorPolygon makePolygon() {
    return FlutterActorPolygon();
  }

  ActorEllipse makeEllipse() {
    return FlutterActorEllipse();
  }

  ColorFill makeColorFill() {
    return FlutterColorFill();
  }

  ColorStroke makeColorStroke() {
    return FlutterColorStroke();
  }

  GradientFill makeGradientFill() {
    return FlutterGradientFill();
  }

  GradientStroke makeGradientStroke() {
    return FlutterGradientStroke();
  }

  RadialGradientFill makeRadialFill() {
    return FlutterRadialFill();
  }

  RadialGradientStroke makeRadialStroke() {
    return FlutterRadialStroke();
  }

  Future<bool> loadFromBundle(AssetBundle assetBundle, String filename) async {
    ByteData data = await assetBundle.load(filename);
    return super.load(data, _AssetBundleContext(assetBundle, filename));
  }

  dispose() {}

  @override
  Future<bool> loadAtlases(List<Uint8List> rawAtlases) async {
    List<ui.Codec> codecs = await Future.wait(
        rawAtlases.map((Uint8List buffer) => ui.instantiateImageCodec(buffer)));
    List<ui.FrameInfo> frames =
        await Future.wait(codecs.map((ui.Codec codec) => codec.getNextFrame()));
    _images =
        frames.map((ui.FrameInfo frame) => frame.image).toList(growable: false);
    return true;
  }

  @override
  Future<Uint8List> readOutOfBandAsset(
      String assetFilename, dynamic context) async {
    _AssetBundleContext bundleContext = context;
    int pathIdx = bundleContext.filename.lastIndexOf('/') + 1;
    String basePath = bundleContext.filename.substring(0, pathIdx);
    ByteData data = await bundleContext.bundle.load(basePath + assetFilename);
    return Uint8List.view(data.buffer);
  }
}

class FlutterActorArtboard extends ActorArtboard {
  FlutterActorArtboard(FlutterActor actor) : super(actor);

  void advance(double seconds) {
    super.advance(seconds);
  }

  void draw(ui.Canvas canvas) {
    for (ActorDrawable drawable in drawableNodes) {
      if (drawable is FlutterActorDrawable) {
        (drawable as FlutterActorDrawable).draw(canvas);
      }
    }
  }

  ActorArtboard makeInstance() {
    FlutterActorArtboard artboardInstance = FlutterActorArtboard(actor);
    artboardInstance.copyArtboard(this);
    return artboardInstance;
  }

  void dispose() {}
}

class FlutterActorPath extends ActorPath with FlutterPathPointsPath {
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    FlutterActorPath instanceNode = FlutterActorPath();
    instanceNode.copyPath(this, resetArtboard);
    return instanceNode;
  }
}

class FlutterActorEllipse extends ActorEllipse with FlutterPathPointsPath {
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    FlutterActorEllipse instanceNode = FlutterActorEllipse();
    instanceNode.copyPath(this, resetArtboard);
    return instanceNode;
  }
}

class FlutterActorPolygon extends ActorPolygon with FlutterPathPointsPath {
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    FlutterActorPolygon instanceNode = FlutterActorPolygon();
    instanceNode.copyPolygon(this, resetArtboard);
    return instanceNode;
  }
}

class FlutterActorStar extends ActorStar with FlutterPathPointsPath {
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    FlutterActorStar instanceNode = FlutterActorStar();
    instanceNode.copyStar(this, resetArtboard);
    return instanceNode;
  }
}

class FlutterActorRectangle extends ActorRectangle with FlutterPathPointsPath {
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    FlutterActorRectangle instanceNode = FlutterActorRectangle();
    instanceNode.copyRectangle(this, resetArtboard);
    return instanceNode;
  }
}

class FlutterActorTriangle extends ActorTriangle with FlutterPathPointsPath {
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    FlutterActorTriangle instanceNode = FlutterActorTriangle();
    instanceNode.copyPath(this, resetArtboard);
    return instanceNode;
  }
}

// Abstract base path that can be invalidated and somehow regenerates, no concrete logic
abstract class FlutterPath {
  ui.Path get path;
}

// Abstract path that uses Actor PathPoints, slightly higher level that FlutterPath.
// Most shapes can use this, but if they want to use a different procedural backing call,
// they should implement FlutterPath and generate the path another way.
abstract class FlutterPathPointsPath implements FlutterPath {
  ui.Path _path = ui.Path();
  List<PathPoint> get deformedPoints;
  bool get isClosed;
  bool _isValid = false;

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
    List<PathPoint> pts = this.deformedPoints;
    if (pts == null || pts.length == 0) {
      return _path;
    }

    List<PathPoint> renderPoints = List<PathPoint>();
    int pl = pts.length;

    const double arcConstant = 0.55;
    const double iarcConstant = 1.0 - arcConstant;
    PathPoint previous = isClosed ? pts[pl - 1] : null;
    for (int i = 0; i < pl; i++) {
      PathPoint point = pts[i];
      switch (point.pointType) {
        case PointType.Straight:
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
        if (cout == null) {
          cout = point.translation;
        }
        if (cin == null) {
          cin = nextPoint.translation;
        }

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
  Int32List _indices;

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
    if (this.textureIndex != value) {
      _paint = ui.Paint()
        ..blendMode = blendMode
        ..shader = ui.ImageShader(
            (artboard.actor as FlutterActor).images[textureIndex],
            ui.TileMode.clamp,
            ui.TileMode.clamp,
            _identityMatrix)
        ..filterQuality = ui.FilterQuality.low
        ..isAntiAlias = true;
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
    }
  }

  void initializeGraphics() {
    super.initializeGraphics();
    if (triangles == null) {
      return;
    }
    _vertexBuffer = makeVertexPositionBuffer();
    _uvBuffer = makeVertexUVBuffer();
    _indices =
        Int32List.fromList(triangles); // nima runtime loads 16 bit indices
    updateVertexUVBuffer(_uvBuffer);
    int count = vertexCount;
    int idx = 0;
    ui.Image image = (artboard.actor as FlutterActor).images[textureIndex];

    // SKIA requires texture coordinates in full image space, not traditional normalized uv coordinates.
    for (int i = 0; i < count; i++) {
      _uvBuffer[idx] = _uvBuffer[idx] * image.width;
      _uvBuffer[idx + 1] = _uvBuffer[idx + 1] * image.height;
      idx += 2;
    }

    if (this.sequenceUVs != null) {
      for (int i = 0; i < this.sequenceUVs.length; i++) {
        this.sequenceUVs[i++] *= image.width;
        this.sequenceUVs[i] *= image.height;
      }
    }

    _paint = ui.Paint()
      ..blendMode = blendMode
      ..shader = ui.ImageShader(
          (artboard.actor as FlutterActor).images[textureIndex],
          ui.TileMode.clamp,
          ui.TileMode.clamp,
          _identityMatrix);
    _paint.filterQuality = ui.FilterQuality.low;
    _paint.isAntiAlias = true;
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

    //Float32List test = new Float32List.fromList([64.0, 32.0, 0.0, 224.0, 128.0, 224.0]);
    //Int32List colorTest = new Int32List.fromList([const ui.Color.fromARGB(255, 0, 255, 0).value, const ui.Color.fromARGB(255, 0, 255, 0).value, const ui.Color.fromARGB(255, 0, 255, 0).value]);
    //_canvasVertices = new ui.Vertices.raw(ui.VertexMode.triangles, test, colors:colorTest /*textureCoordinates: _uvBuffer, indices: _indices*/);
    // int uvOffset;

    // if (this.sequenceUVs != null) {
    //   int framesCount = this.sequenceFrames.length;
    //   int currentFrame = this.sequenceFrame % framesCount;

    //   SequenceFrame sf = this.sequenceFrames[currentFrame];
    //   uvOffset = sf.offset;
    //   textureIndex = sf.atlasIndex;

    //   int uvStride = 8;
    //   int uvRow = currentFrame * uvStride;
    //   Iterable<double> it = this.sequenceUVs.getRange(uvRow, uvRow + uvStride);
    //   List<double> uvList = List.from(it);
    //   _uvBuffer = Float32List.fromList(uvList);
    // }
    _canvasVertices = ui.Vertices.raw(ui.VertexMode.triangles, _vertexBuffer,
        indices: _indices, textureCoordinates: _uvBuffer);
    return true;
  }

  draw(ui.Canvas canvas) {
    if (triangles == null || renderCollapsed || renderOpacity <= 0) {
      return;
    }

    if (_canvasVertices == null && !updateVertices()) {
      return;
    }
    
    // Get Clips
    for (List<ActorShape> clips in clipShapes) {
      if (clips.length == 1) {
        canvas.clipPath((clips[0] as FlutterActorShape).path);
      } else {
        ui.Path clippingPath = ui.Path();
        for (ActorShape clipShape in clips) {
          clippingPath.addPath(
              (clipShape as FlutterActorShape).path, ui.Offset.zero);
        }
        canvas.clipPath(clippingPath);
      }
    }

    _paint.color = _paint.color.withOpacity(renderOpacity);
    if (imageTransform != null) {
      canvas.save();
      canvas.transform(imageTransform.mat4);
      canvas.drawVertices(_canvasVertices, ui.BlendMode.srcOver, _paint);
      canvas.restore();
    } else {
      canvas.drawVertices(_canvasVertices, ui.BlendMode.srcOver, _paint);
    }
  }

  @override
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    FlutterActorImage instanceNode = FlutterActorImage();
    instanceNode.copyImage(this, resetArtboard);
    return instanceNode;
  }

  AABB computeAABB() {
    this.updateVertices();

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
}
