import "dart:math";

import "actor_artboard.dart";
import "actor_component.dart";
import "actor_node.dart";
import "actor_path.dart";
import "math/vec2d.dart";
import "path_point.dart";
import "stream_reader.dart";

class ActorPolygon extends ActorProceduralPath {
  int sides = 5;
  @override
  void invalidatePath() {}

  @override
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    ActorPolygon instance = ActorPolygon();
    instance.copyPolygon(this, resetArtboard);
    return instance;
  }

  void copyPolygon(ActorPolygon node, ActorArtboard resetArtboard) {
    copyPath(node, resetArtboard);
    sides = node.sides;
  }

  static ActorPolygon read(
      ActorArtboard artboard, StreamReader reader, ActorPolygon component) {
    ActorNode.read(artboard, reader, component);

    component.width = reader.readFloat32("width");
    component.height = reader.readFloat32("height");
    component.sides = reader.readUint32("sides");
    return component;
  }

  @override
  List<PathPoint> get points {
    List<PathPoint> _polygonPoints = <PathPoint>[];
    double angle = -pi / 2.0;
    double inc = (pi * 2.0) / sides;

    for (int i = 0; i < sides; i++) {
      _polygonPoints.add(StraightPathPoint.fromTranslation(
          Vec2D.fromValues(cos(angle) * radiusX, sin(angle) * radiusY)));
      angle += inc;
    }

    return _polygonPoints;
  }

  bool get isClosed => true;
  bool get doesDraw => !renderCollapsed;
  double get radiusX => width! / 2;
  double get radiusY => height! / 2;
}
