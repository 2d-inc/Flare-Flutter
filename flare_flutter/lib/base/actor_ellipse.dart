import 'package:flare_flutter/base/actor_artboard.dart';
import 'package:flare_flutter/base/actor_component.dart';
import 'package:flare_flutter/base/actor_node.dart';
import 'package:flare_flutter/base/actor_path.dart';
import 'package:flare_flutter/base/math/vec2d.dart';
import 'package:flare_flutter/base/path_point.dart';
import 'package:flare_flutter/base/stream_reader.dart';

const double circleConstant = 0.55;

class ActorEllipse extends ActorProceduralPath {
  bool get doesDraw {
    return !renderCollapsed;
  }

  bool get isClosed => true;

  @override
  List<PathPoint> get points {
    List<PathPoint> _ellipsePathPoints = <PathPoint>[];
    _ellipsePathPoints.add(CubicPathPoint.fromValues(
        Vec2D.fromValues(0.0, -radiusY),
        Vec2D.fromValues(-radiusX * circleConstant, -radiusY),
        Vec2D.fromValues(radiusX * circleConstant, -radiusY)));
    _ellipsePathPoints.add(CubicPathPoint.fromValues(
        Vec2D.fromValues(radiusX, 0.0),
        Vec2D.fromValues(radiusX, circleConstant * -radiusY),
        Vec2D.fromValues(radiusX, circleConstant * radiusY)));
    _ellipsePathPoints.add(CubicPathPoint.fromValues(
        Vec2D.fromValues(0.0, radiusY),
        Vec2D.fromValues(radiusX * circleConstant, radiusY),
        Vec2D.fromValues(-radiusX * circleConstant, radiusY)));
    _ellipsePathPoints.add(CubicPathPoint.fromValues(
        Vec2D.fromValues(-radiusX, 0.0),
        Vec2D.fromValues(-radiusX, radiusY * circleConstant),
        Vec2D.fromValues(-radiusX, -radiusY * circleConstant)));

    return _ellipsePathPoints;
  }

  double get radiusX => width / 2;

  double get radiusY => height / 2;

  @override
  void invalidatePath() {}

  @override
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    ActorEllipse instance = ActorEllipse();
    instance.copyPath(this, resetArtboard);
    return instance;
  }
  static ActorEllipse read(
      ActorArtboard artboard, StreamReader reader, ActorEllipse component) {
    ActorNode.read(artboard, reader, component);

    component.width = reader.readFloat32('width');
    component.height = reader.readFloat32('height');
    return component;
  }
}
