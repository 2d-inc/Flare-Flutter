import "actor_component.dart";
import "actor_artboard.dart";
import "actor_node.dart";
import "math/vec2d.dart";
import "stream_reader.dart";
import "actor_path.dart";
import "path_point.dart";

const double CircleConstant = 0.55;

class ActorEllipse extends ActorProceduralPath {
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    ActorEllipse instance = ActorEllipse();
    instance.copyPath(this, resetArtboard);
    return instance;
  }

  @override
  void invalidatePath() {}

  static ActorEllipse read(
      ActorArtboard artboard, StreamReader reader, ActorEllipse component) {
    if (component == null) {
      component = ActorEllipse();
    }

    ActorNode.read(artboard, reader, component);

    component.width = reader.readFloat32("width");
    component.height = reader.readFloat32("height");
    return component;
  }

  @override
  List<PathPoint> get points {
    List<PathPoint> _ellipsePathPoints = <PathPoint>[];
    _ellipsePathPoints.add(CubicPathPoint.fromValues(
        Vec2D.fromValues(0.0, -radiusY),
        Vec2D.fromValues(-radiusX * CircleConstant, -radiusY),
        Vec2D.fromValues(radiusX * CircleConstant, -radiusY)));
    _ellipsePathPoints.add(CubicPathPoint.fromValues(
        Vec2D.fromValues(radiusX, 0.0),
        Vec2D.fromValues(radiusX, CircleConstant * -radiusY),
        Vec2D.fromValues(radiusX, CircleConstant * radiusY)));
    _ellipsePathPoints.add(CubicPathPoint.fromValues(
        Vec2D.fromValues(0.0, radiusY),
        Vec2D.fromValues(radiusX * CircleConstant, radiusY),
        Vec2D.fromValues(-radiusX * CircleConstant, radiusY)));
    _ellipsePathPoints.add(CubicPathPoint.fromValues(
        Vec2D.fromValues(-radiusX, 0.0),
        Vec2D.fromValues(-radiusX, radiusY * CircleConstant),
        Vec2D.fromValues(-radiusX, -radiusY * CircleConstant)));

    return _ellipsePathPoints;
  }

  bool get isClosed => true;

  bool get doesDraw {
    return !this.renderCollapsed;
  }

  double get radiusX => this.width / 2;
  double get radiusY => this.height / 2;
}
