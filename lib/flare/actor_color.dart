import "dart:typed_data";
import 'math/mat2d.dart';

import "actor_node.dart";
import "actor_shape.dart";
import "actor_artboard.dart";

import "actor_component.dart";
import "dart:collection";
import "stream_reader.dart";
import "math/vec2d.dart";

enum FillRule { EvenOdd, NonZero }
enum StrokeCap { Butt, Round, Square }
enum StrokeJoin { Miter, Round, Bevel }

HashMap<int, FillRule> fillRuleLookup = HashMap<int, FillRule>.fromIterables(
    [0, 1], [FillRule.EvenOdd, FillRule.NonZero]);
HashMap<int, StrokeCap> strokeCapLookup = HashMap<int, StrokeCap>.fromIterables(
    [0, 1, 2], [StrokeCap.Butt, StrokeCap.Round, StrokeCap.Square]);
HashMap<int, StrokeJoin> strokeJoinLookup =
    HashMap<int, StrokeJoin>.fromIterables(
        [0, 1, 2], [StrokeJoin.Miter, StrokeJoin.Round, StrokeJoin.Bevel]);

abstract class ActorPaint extends ActorComponent {
  double opacity = 1.0;

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

  completeResolve() {
    artboard.addDependency(this, parent);
  }
}

abstract class ActorColor extends ActorPaint {
  Float32List _color = Float32List(4);

  Float32List get color {
    return _color;
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

    reader.readFloat32ArrayOffset(component._color, 4, 0, "color");

    return component;
  }

  void onDirty(int dirt) {}
  void update(int dirt) {}
}

class ActorFill {
  FillRule _fillRule = FillRule.EvenOdd;
  FillRule get fillRule => _fillRule;

  static void read(
      ActorArtboard artboard, StreamReader reader, ActorFill component) {
    component._fillRule = fillRuleLookup[reader.readUint8("fillRule")];
  }

  void copyFill(ActorFill node, ActorArtboard resetArtboard) {
    _fillRule = node._fillRule;
  }
}

abstract class ActorStroke {
  double width = 1.0;
  StrokeCap _cap = StrokeCap.Butt;
  StrokeJoin _join = StrokeJoin.Miter;
  StrokeCap get cap => _cap;
  StrokeJoin get join => _join;
  static void read(
      ActorArtboard artboard, StreamReader reader, ActorStroke component) {
    component.width = reader.readFloat32("width");
    if (artboard.actor.version >= 19) {
      component._cap = strokeCapLookup[reader.readUint8("cap")];
      component._join = strokeJoinLookup[reader.readUint8("join")];
    }
  }

  void copyStroke(ActorStroke node, ActorArtboard resetArtboard) {
    width = node.width;
    _cap = node._cap;
    _join = node._join;
  }
}

class ColorFill extends ActorColor with ActorFill {
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    ColorFill instanceEvent = ColorFill();
    instanceEvent.copyColorFill(this, resetArtboard);
    return instanceEvent;
  }

  void copyColorFill(ColorFill node, ActorArtboard resetArtboard) {
    copyColor(node, resetArtboard);
    copyFill(node, resetArtboard);
  }

  static ColorFill read(
      ActorArtboard artboard, StreamReader reader, ColorFill component) {
    if (component == null) {
      component = ColorFill();
    }
    ActorColor.read(artboard, reader, component);
    ActorFill.read(artboard, reader, component);
    return component;
  }
}

class ColorStroke extends ActorColor with ActorStroke {
  double get opacity => _color[3];

  set opacity(double val) {
    this.color[3] = val;
  }

  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    ColorStroke instanceEvent = ColorStroke();
    instanceEvent.copyColorStroke(this, resetArtboard);
    return instanceEvent;
  }

  void copyColorStroke(ColorStroke node, ActorArtboard resetArtboard) {
    copyColor(node, resetArtboard);
    copyStroke(node, resetArtboard);
  }

  static ColorStroke read(
      ActorArtboard artboard, StreamReader reader, ColorStroke component) {
    if (component == null) {
      component = ColorStroke();
    }
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
    Float32List stops = Float32List(numStops * 5);
    reader.readFloat32ArrayOffset(stops, numStops * 5, 0, "colorStops");
    component._colorStops = stops;

    reader.readFloat32ArrayOffset(component._start.values, 2, 0, "start");
    reader.readFloat32ArrayOffset(component._end.values, 2, 0, "end");

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

class GradientFill extends GradientColor with ActorFill {
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    GradientFill instanceEvent = GradientFill();
    instanceEvent.copyGradientFill(this, resetArtboard);
    return instanceEvent;
  }

  void copyGradientFill(GradientFill node, ActorArtboard resetArtboard) {
    copyGradient(node, resetArtboard);
    copyFill(node, resetArtboard);
  }

  static GradientFill read(
      ActorArtboard artboard, StreamReader reader, GradientFill component) {
    if (component == null) {
      component = GradientFill();
    }
    GradientColor.read(artboard, reader, component);
    component._fillRule = fillRuleLookup[reader.readUint8("fillRule")];
    return component;
  }
}

class GradientStroke extends GradientColor with ActorStroke {
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    GradientStroke instanceEvent = GradientStroke();
    instanceEvent.copyGradientStroke(this, resetArtboard);
    return instanceEvent;
  }

  void copyGradientStroke(GradientStroke node, ActorArtboard resetArtboard) {
    copyGradient(node, resetArtboard);
    copyStroke(node, resetArtboard);
  }

  static GradientStroke read(
      ActorArtboard artboard, StreamReader reader, GradientStroke component) {
    if (component == null) {
      component = GradientStroke();
    }
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

class RadialGradientFill extends RadialGradientColor with ActorFill {
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    RadialGradientFill instanceEvent = RadialGradientFill();
    instanceEvent.copyRadialFill(this, resetArtboard);
    return instanceEvent;
  }

  void copyRadialFill(RadialGradientFill node, ActorArtboard resetArtboard) {
    copyRadialGradient(node, resetArtboard);
    copyFill(node, resetArtboard);
  }

  static RadialGradientFill read(ActorArtboard artboard, StreamReader reader,
      RadialGradientFill component) {
    if (component == null) {
      component = RadialGradientFill();
    }
    RadialGradientColor.read(artboard, reader, component);
    ActorFill.read(artboard, reader, component);

    return component;
  }
}

class RadialGradientStroke extends RadialGradientColor with ActorStroke {
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    RadialGradientStroke instanceEvent = RadialGradientStroke();
    instanceEvent.copyRadialStroke(this, resetArtboard);
    return instanceEvent;
  }

  void copyRadialStroke(
      RadialGradientStroke node, ActorArtboard resetArtboard) {
    copyRadialGradient(node, resetArtboard);
    copyStroke(node, resetArtboard);
  }

  static RadialGradientStroke read(ActorArtboard artboard, StreamReader reader,
      RadialGradientStroke component) {
    if (component == null) {
      component = RadialGradientStroke();
    }
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
