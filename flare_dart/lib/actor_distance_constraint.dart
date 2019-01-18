import "actor_artboard.dart";
import "actor_node.dart";
import "actor_targeted_constraint.dart";
import "stream_reader.dart";
import "math/vec2d.dart";
import "math/mat2d.dart";

class DistanceMode {
  static const int Closer = 0;
  static const int Further = 1;
  static const int Exact = 2;
}

class ActorDistanceConstraint extends ActorTargetedConstraint {
  double _distance = 100.0;
  int _mode = DistanceMode.Closer;

  ActorDistanceConstraint() : super();

  static ActorDistanceConstraint read(ActorArtboard artboard,
      StreamReader reader, ActorDistanceConstraint component) {
    if (component == null) {
      component = ActorDistanceConstraint();
    }
    ActorTargetedConstraint.read(artboard, reader, component);

    component._distance = reader.readFloat32("distance");
    component._mode = reader.readUint8("modeId");

    return component;
  }

  @override
  ActorDistanceConstraint makeInstance(ActorArtboard resetArtboard) {
    ActorDistanceConstraint node = ActorDistanceConstraint();
    node.copyDistanceConstraint(this, resetArtboard);
    return node;
  }

  void copyDistanceConstraint(
      ActorDistanceConstraint node, ActorArtboard resetArtboard) {
    copyTargetedConstraint(node, resetArtboard);
    _distance = node._distance;
    _mode = node._mode;
  }

  @override
  constrain(ActorNode node) {
    ActorNode t = this.target;
    if (t == null) {
      return;
    }

    ActorNode p = this.parent;
    Vec2D targetTranslation = t.getWorldTranslation(Vec2D());
    Vec2D ourTranslation = p.getWorldTranslation(Vec2D());

    Vec2D toTarget = Vec2D.subtract(Vec2D(), ourTranslation, targetTranslation);
    double currentDistance = Vec2D.length(toTarget);
    switch (_mode) {
      case DistanceMode.Closer:
        if (currentDistance < _distance) {
          return;
        }
        break;

      case DistanceMode.Further:
        if (currentDistance > _distance) {
          return;
        }
        break;
    }

    if (currentDistance < 0.001) {
      return;
    }

    Vec2D.scale(toTarget, toTarget, 1.0 / currentDistance);
    Vec2D.scale(toTarget, toTarget, _distance);

    Mat2D world = p.worldTransform;
    Vec2D position = Vec2D.lerp(Vec2D(), ourTranslation,
        Vec2D.add(Vec2D(), targetTranslation, toTarget), strength);
    world[4] = position[0];
    world[5] = position[1];
  }

  void update(int dirt) {}
  void completeResolve() {}

  get distance => _distance;
  get mode => _mode;

  set distance(double d) {
    if (_distance != d) {
      _distance = d;
      this.markDirty();
    }
  }

  set mode(int m) {
    if (_mode != m) {
      _mode = m;
      this.markDirty();
    }
  }
}
