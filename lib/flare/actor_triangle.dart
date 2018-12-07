import "actor_artboard.dart";
import "actor_node.dart";
import "math/vec2d.dart";
import "stream_reader.dart";
import "actor_path.dart";
import "path_point.dart";
import "actor_component.dart";

class ActorTriangle extends ActorProceduralPath {
  @override
  void invalidatePath() {}

  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    ActorTriangle instance = ActorTriangle();
    instance.copyPath(this, resetArtboard);
    return instance;
  }

  static ActorTriangle read(
      ActorArtboard artboard, StreamReader reader, ActorTriangle component) {
    if (component == null) {
      component = ActorTriangle();
    }

    ActorNode.read(artboard, reader, component);

    component.width = reader.readFloat32("width");
    component.height = reader.readFloat32("height");
    return component;
  }

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

  bool get isClosed => true;
  bool get doesDraw => !this.renderCollapsed;
  double get radiusX => this.width / 2;
  double get radiusY => this.height / 2;
}
