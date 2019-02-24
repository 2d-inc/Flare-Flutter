import "actor_artboard.dart";
import "actor_node.dart";
import "math/vec2d.dart";
import "stream_reader.dart";
import "actor_path.dart";
import "path_point.dart";
import "actor_component.dart";

const double CircleConstant = 0.55;

class ActorRectangle extends ActorProceduralPath {
  double _radius = 0.0;

  @override
  void invalidatePath() {}

  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    ActorRectangle instance = ActorRectangle();
    instance.copyRectangle(this, resetArtboard);
    return instance;
  }

  void copyRectangle(ActorRectangle node, ActorArtboard resetArtboard) {
    copyPath(node, resetArtboard);
    _radius = node._radius;
  }

  static ActorRectangle read(
      ActorArtboard artboard, StreamReader reader, ActorRectangle component) {
    if (component == null) {
      component = ActorRectangle();
    }

    ActorNode.read(artboard, reader, component);

    component.width = reader.readFloat32("width");
    component.height = reader.readFloat32("height");
    component._radius = reader.readFloat32("cornerRadius");
    return component;
  }

  @override
  List<PathPoint> get points {
    double halfWidth = width / 2.0;
    double halfHeight = height / 2.0;
    List<PathPoint> _rectanglePathPoints = <PathPoint>[];
    _rectanglePathPoints.add(StraightPathPoint.fromValues(
        Vec2D.fromValues(-halfWidth, -halfHeight), _radius));
    _rectanglePathPoints.add(StraightPathPoint.fromValues(
        Vec2D.fromValues(halfWidth, -halfHeight), _radius));
    _rectanglePathPoints.add(StraightPathPoint.fromValues(
        Vec2D.fromValues(halfWidth, halfHeight), _radius));
    _rectanglePathPoints.add(StraightPathPoint.fromValues(
        Vec2D.fromValues(-halfWidth, halfHeight), _radius));

    return _rectanglePathPoints;
  }

  set radius(double rd) {
    if (rd != _radius) {
      _radius = rd;
      invalidateDrawable();
    }
  }

  bool get isClosed => true;

  bool get doesDraw {
    return !renderCollapsed;
  }

  double get radius => _radius;
}
