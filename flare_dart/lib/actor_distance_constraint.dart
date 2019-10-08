import "actor_artboard.dart";
import "actor_node.dart";
import "actor_targeted_constraint.dart";
import "math/mat2d.dart";
import "math/vec2d.dart";
import "stream_reader.dart";

class DistanceMode {
  static const int closer = 0;
  static const int further = 1;
  static const int exact = 2;
}

class ActorDistanceConstraint extends ActorTargetedConstraint {
  double _distance = 100.0;
  int _mode = DistanceMode.closer;

  ActorDistanceConstraint() : super();

  static ActorDistanceConstraint read(ActorArtboard artboard,
      StreamReader reader, ActorDistanceConstraint component) {
    component ??= ActorDistanceConstraint();
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
  void constrain(ActorNode node) {
    ActorNode t = target as ActorNode;
    if (t == null) {
      return;
    }

    ActorNode p = parent;
    Vec2D targetTranslation = t.getWorldTranslation(Vec2D());
    Vec2D ourTranslation = p.getWorldTranslation(Vec2D());

    Vec2D toTarget = Vec2D.subtract(Vec2D(), ourTranslation, targetTranslation);
    double currentDistance = Vec2D.length(toTarget);
    switch (_mode) {
      case DistanceMode.closer:
        if (currentDistance < _distance) {
          return;
        }
        break;

      case DistanceMode.further:
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

  double get distance => _distance;
  int get mode => _mode;

  set distance(double d) {
    if (_distance != d) {
      _distance = d;
      markDirty();
    }
  }

  set mode(int m) {
    if (_mode != m) {
      _mode = m;
      markDirty();
    }
  }

  @override
  void completeResolve() {}

  @override
  void update(int dirt) {}
}
