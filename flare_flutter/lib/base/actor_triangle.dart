import 'package:flare_flutter/base/actor_artboard.dart';
import 'package:flare_flutter/base/actor_component.dart';
import 'package:flare_flutter/base/actor_node.dart';
import 'package:flare_flutter/base/actor_path.dart';
import 'package:flare_flutter/base/math/vec2d.dart';
import 'package:flare_flutter/base/path_point.dart';
import 'package:flare_flutter/base/stream_reader.dart';

class ActorTriangle extends ActorProceduralPath {
  bool get doesDraw => !renderCollapsed;

  bool get isClosed => true;

  @override
  List<PathPoint> get points {
    List<PathPoint> _trianglePoints = <PathPoint>[];
    _trianglePoints.add(
        StraightPathPoint.fromTranslation(Vec2D.fromValues(0.0, -radiusY)));
    _trianglePoints.add(
        StraightPathPoint.fromTranslation(Vec2D.fromValues(radiusX, radiusY)));
    _trianglePoints.add(
        StraightPathPoint.fromTranslation(Vec2D.fromValues(-radiusX, radiusY)));

    return _trianglePoints;
  }

  double get radiusX => width / 2;

  double get radiusY => height / 2;
  @override
  void invalidatePath() {}
  @override
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    ActorTriangle instance = ActorTriangle();
    instance.copyPath(this, resetArtboard);
    return instance;
  }
  static ActorTriangle read(
      ActorArtboard artboard, StreamReader reader, ActorTriangle component) {
    ActorNode.read(artboard, reader, component);

    component.width = reader.readFloat32('width');
    component.height = reader.readFloat32('height');
    return component;
  }
}
