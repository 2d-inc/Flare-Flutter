import "dart:typed_data";
import 'math/mat2d.dart';

import "actor_node.dart";
import "actor_shape.dart";
import "actor_artboard.dart";

import "actor_component.dart";
import "dart:collection";
import "stream_reader.dart";
import "math/vec2d.dart";
import "actor_flags.dart";

enum FillRule { EvenOdd, NonZero }
enum StrokeCap { Butt, Round, Square }
enum StrokeJoin { Miter, Round, Bevel }
enum TrimPath { Off, Sequential, Synced }

final HashMap<int, FillRule> fillRuleLookup =
    HashMap<int, FillRule>.fromIterables(
        [0, 1], [FillRule.EvenOdd, FillRule.NonZero]);
final HashMap<int, StrokeCap> strokeCapLookup =
    HashMap<int, StrokeCap>.fromIterables(
        [0, 1, 2], [StrokeCap.Butt, StrokeCap.Round, StrokeCap.Square]);
final HashMap<int, StrokeJoin> strokeJoinLookup =
    HashMap<int, StrokeJoin>.fromIterables(
        [0, 1, 2], [StrokeJoin.Miter, StrokeJoin.Round, StrokeJoin.Bevel]);
final HashMap<int, TrimPath> trimPathLookup =
    HashMap<int, TrimPath>.fromIterables(
        [0, 1, 2], [TrimPath.Off, TrimPath.Sequential, TrimPath.Synced]);

abstract class ActorPaint extends ActorComponent {
  double _opacity = 1.0;
  double get opacity => _opacity;
  set opacity(double value) {
    if (value == _opacity) {
      return;
    }
    _opacity = value;
    markPaintDirty();
  }

  void copyPaint(ActorPaint component, ActorArtboard resetArtboard) {
    copyComponent(component, resetArtboard);
    opacity = component.opacity;
  }

  static ActorPaint read(
      ActorArtboard artboard, StreamReader reader, ActorPaint component) {
    ActorComponent.read(artboard, reader, component);
    component.opacity = reader.readFloat32("opacity");

    return component;
  }

  void completeResolve() {
    artboard.addDependency(this, parent);
  }

  ActorShape get shape => parent as ActorShape;

  void markPaintDirty() {
    artboard.addDirt(this, DirtyFlags.PaintDirty, false);
  }
}

abstract class ActorColor extends ActorPaint {
  Float32List _color = Float32List(4);

  Float32List get color {
    return _color;
  }

  Float32List get displayColor {
    return artboard?.overrideColor ?? _color;
  }

  set color(Float32List value) {
    if (value.length != 4) {
      return;
    }
    _color[0] = value[0];
    _color[1] = value[1];
    _color[2] = value[2];
    _color[3] = value[3];
    markPaintDirty();
  }

  void copyColor(ActorColor node, ActorArtboard resetArtboard) {
    copyPaint(node, resetArtboard);
    _color[0] = node._color[0];
    _color[1] = node._color[1];
    _color[2] = node._color[2];
    _color[3] = node._color[3];
  }

  static ActorColor read(
      ActorArtboard artboard, StreamReader reader, ActorColor component) {
    ActorPaint.read(artboard, reader, component);

    component._color = reader.readFloat32Array(4, "color");

    return component;
  }

  void onDirty(int dirt) {}
  void update(int dirt) {}
}

abstract class ActorFill {
  FillRule _fillRule = FillRule.EvenOdd;
  FillRule get fillRule => _fillRule;

  static void read(
      ActorArtboard artboard, StreamReader reader, ActorFill component) {
    component._fillRule = fillRuleLookup[reader.readUint8("fillRule")];
  }

  void copyFill(ActorFill node, ActorArtboard resetArtboard) {
    _fillRule = node._fillRule;
  }

  void initializeGraphics();
}

abstract class ActorStroke {
  double _width = 1.0;
  double get width => _width;
  set width(double value) {
    if (value == _width) {
      return;
    }
    _width = value;
    markPaintDirty();
  }

  StrokeCap _cap = StrokeCap.Butt;
  StrokeJoin _join = StrokeJoin.Miter;
  StrokeCap get cap => _cap;
  StrokeJoin get join => _join;

  TrimPath _trim = TrimPath.Off;

  TrimPath get trim => _trim;
  bool get isTrimmed => _trim != TrimPath.Off;

  double _trimStart = 0.0;
  double get trimStart => _trimStart;
  set trimStart(double value) {
    if (_trimStart == value) {
      return;
    }
    _trimStart = value;
    markPathEffectsDirty();
  }

  double _trimEnd = 0.0;
  double get trimEnd => _trimEnd;
  set trimEnd(double value) {
    if (_trimEnd == value) {
      return;
    }
    _trimEnd = value;
    markPathEffectsDirty();
  }

  double _trimOffset = 0.0;
  double get trimOffset => _trimOffset;
  set trimOffset(double value) {
    if (_trimOffset == value) {
      return;
    }
    _trimOffset = value;
    markPathEffectsDirty();
  }

  void markPaintDirty();
  void markPathEffectsDirty();

  static void read(
      ActorArtboard artboard, StreamReader reader, ActorStroke component) {
    component.width = reader.readFloat32("width");
    if (artboard.actor.version >= 19) {
      component._cap = strokeCapLookup[reader.readUint8("cap")];
      component._join = strokeJoinLookup[reader.readUint8("join")];
      if (artboard.actor.version >= 20) {
        component._trim =
            trimPathLookup[reader.readUint8("trim")] ?? TrimPath.Off;
        if (component.isTrimmed) {
          component._trimStart = reader.readFloat32("start");
          component._trimEnd = reader.readFloat32("end");
          component._trimOffset = reader.readFloat32("offset");
        }
      }
    }
  }

  void copyStroke(ActorStroke node, ActorArtboard resetArtboard) {
    width = node.width;
    _cap = node._cap;
    _join = node._join;
    _trim = node._trim;
    _trimStart = node._trimStart;
    _trimEnd = node._trimEnd;
    _trimOffset = node._trimOffset;
  }

  void initializeGraphics();
}

abstract class ColorFill extends ActorColor with ActorFill {
  void copyColorFill(ColorFill node, ActorArtboard resetArtboard) {
    copyColor(node, resetArtboard);
    copyFill(node, resetArtboard);
  }

  static ColorFill read(
      ActorArtboard artboard, StreamReader reader, ColorFill component) {
    ActorColor.read(artboard, reader, component);
    ActorFill.read(artboard, reader, component);
    return component;
  }

  void completeResolve() {
    super.completeResolve();

    ActorNode parentNode = parent;
    if (parentNode is ActorShape) {
      parentNode.addFill(this);
    }
  }
}

abstract class ColorStroke extends ActorColor with ActorStroke {
  void copyColorStroke(ColorStroke node, ActorArtboard resetArtboard) {
    copyColor(node, resetArtboard);
    copyStroke(node, resetArtboard);
  }

  static ColorStroke read(
      ActorArtboard artboard, StreamReader reader, ColorStroke component) {
    ActorColor.read(artboard, reader, component);
    ActorStroke.read(artboard, reader, component);
    return component;
  }

  void completeResolve() {
    super.completeResolve();

    ActorNode parentNode = parent;
    if (parentNode is ActorShape) {
      parentNode.addStroke(this);
    }
  }
}

abstract class GradientColor extends ActorPaint {
  Float32List _colorStops = Float32List(10);
  Vec2D _start = Vec2D();
  Vec2D _end = Vec2D();
  Vec2D _renderStart = Vec2D();
  Vec2D _renderEnd = Vec2D();
  double opacity = 1.0;

  Vec2D get start => _start;
  Vec2D get end => _end;
  Vec2D get renderStart => _renderStart;
  Vec2D get renderEnd => _renderEnd;

  Float32List get colorStops {
    return _colorStops;
  }

  void copyGradient(GradientColor node, ActorArtboard resetArtboard) {
    copyPaint(node, resetArtboard);
    _colorStops = Float32List.fromList(node._colorStops);
    Vec2D.copy(_start, node._start);
    Vec2D.copy(_end, node._end);
    opacity = node.opacity;
  }

  static GradientColor read(
      ActorArtboard artboard, StreamReader reader, GradientColor component) {
    ActorPaint.read(artboard, reader, component);

    int numStops = reader.readUint8("numColorStops");
    Float32List stops = reader.readFloat32Array(numStops * 5, "colorStops");
    component._colorStops = stops;

    Vec2D.copyFromList(component._start, reader.readFloat32Array(2, "start"));
    Vec2D.copyFromList(component._end, reader.readFloat32Array(2, "end"));

    return component;
  }

  void onDirty(int dirt) {}
  void update(int dirt) {
    ActorShape shape = parent;
    Mat2D world = shape.worldTransform;
    Vec2D.transformMat2D(_renderStart, _start, world);
    Vec2D.transformMat2D(_renderEnd, _end, world);
  }
}

abstract class GradientFill extends GradientColor with ActorFill {
  void copyGradientFill(GradientFill node, ActorArtboard resetArtboard) {
    copyGradient(node, resetArtboard);
    copyFill(node, resetArtboard);
  }

  static GradientFill read(
      ActorArtboard artboard, StreamReader reader, GradientFill component) {
    GradientColor.read(artboard, reader, component);
    component._fillRule = fillRuleLookup[reader.readUint8("fillRule")];
    return component;
  }

  void completeResolve() {
    super.completeResolve();

    ActorNode parentNode = parent;
    if (parentNode is ActorShape) {
      parentNode.addFill(this);
    }
  }
}

abstract class GradientStroke extends GradientColor with ActorStroke {
  void copyGradientStroke(GradientStroke node, ActorArtboard resetArtboard) {
    copyGradient(node, resetArtboard);
    copyStroke(node, resetArtboard);
  }

  static GradientStroke read(
      ActorArtboard artboard, StreamReader reader, GradientStroke component) {
    GradientColor.read(artboard, reader, component);
    ActorStroke.read(artboard, reader, component);
    return component;
  }

  void completeResolve() {
    super.completeResolve();

    ActorNode parentNode = parent;
    if (parentNode is ActorShape) {
      parentNode.addStroke(this);
    }
  }
}

abstract class RadialGradientColor extends GradientColor {
  double secondaryRadiusScale = 1.0;

  void copyRadialGradient(
      RadialGradientColor node, ActorArtboard resetArtboard) {
    copyGradient(node, resetArtboard);
    secondaryRadiusScale = node.secondaryRadiusScale;
  }

  static RadialGradientColor read(ActorArtboard artboard, StreamReader reader,
      RadialGradientColor component) {
    GradientColor.read(artboard, reader, component);

    component.secondaryRadiusScale = reader.readFloat32("secondaryRadiusScale");

    return component;
  }
}

abstract class RadialGradientFill extends RadialGradientColor with ActorFill {
  void copyRadialFill(RadialGradientFill node, ActorArtboard resetArtboard) {
    copyRadialGradient(node, resetArtboard);
    copyFill(node, resetArtboard);
  }

  static RadialGradientFill read(ActorArtboard artboard, StreamReader reader,
      RadialGradientFill component) {
    RadialGradientColor.read(artboard, reader, component);
    ActorFill.read(artboard, reader, component);

    return component;
  }

  void completeResolve() {
    super.completeResolve();

    ActorNode parentNode = parent;
    if (parentNode is ActorShape) {
      parentNode.addFill(this);
    }
  }
}

abstract class RadialGradientStroke extends RadialGradientColor
    with ActorStroke {
  void copyRadialStroke(
      RadialGradientStroke node, ActorArtboard resetArtboard) {
    copyRadialGradient(node, resetArtboard);
    copyStroke(node, resetArtboard);
  }

  static RadialGradientStroke read(ActorArtboard artboard, StreamReader reader,
      RadialGradientStroke component) {
    RadialGradientColor.read(artboard, reader, component);
    ActorStroke.read(artboard, reader, component);
    return component;
  }

  void completeResolve() {
    super.completeResolve();

    ActorNode parentNode = parent;
    if (parentNode is ActorShape) {
      parentNode.addStroke(this);
    }
  }
}
