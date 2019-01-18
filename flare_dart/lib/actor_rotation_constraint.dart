import "actor_targeted_constraint.dart";
import "actor_node.dart";
import "actor_component.dart";
import "actor_artboard.dart";
import "stream_reader.dart";
import "math/transform_components.dart";
import "math/mat2d.dart";
import "dart:math";
import "transform_space.dart";

class ActorRotationConstraint extends ActorTargetedConstraint {
  static const double PI2 = pi * 2.0;

  bool _copy = false;
  double _scale = 1.0;
  bool _enableMin = false;
  bool _enableMax = false;
  double _max = PI2;
  double _min = -PI2;
  bool _offset = false;
  int _sourceSpace = TransformSpace.World;
  int _destSpace = TransformSpace.World;
  int _minMaxSpace = TransformSpace.World;
  TransformComponents _componentsA = TransformComponents();
  TransformComponents _componentsB = TransformComponents();

  static ActorRotationConstraint read(ActorArtboard artboard,
      StreamReader reader, ActorRotationConstraint component) {
    if (component == null) {
      component = ActorRotationConstraint();
    }
    ActorTargetedConstraint.read(artboard, reader, component);
    component._copy = reader.readBool("copy");
    if (component._copy) {
      component._scale = reader.readFloat32("scale");
    }
    component._enableMin = reader.readBool("enableMin");
    if (component._enableMin) {
      component._min = reader.readFloat32("min");
    }
    component._enableMax = reader.readBool("enableMax");
    if (component._enableMax) {
      component._max = reader.readFloat32("max");
    }

    component._offset = reader.readBool("offset");
    component._sourceSpace = reader.readUint8("sourceSpaceId");
    component._destSpace = reader.readUint8("destSpaceId");
    component._minMaxSpace = reader.readUint8("minMaxSpaceId");

    return component;
  }

  void constrain(ActorNode node) {
    ActorNode target = this.target;
    ActorNode grandParent = parent.parent;

    Mat2D transformA = parent.worldTransform;
    Mat2D transformB = Mat2D();
    Mat2D.decompose(transformA, _componentsA);
    if (target == null) {
      Mat2D.copy(transformB, transformA);
      _componentsB[0] = _componentsA[0];
      _componentsB[1] = _componentsA[1];
      _componentsB[2] = _componentsA[2];
      _componentsB[3] = _componentsA[3];
      _componentsB[4] = _componentsA[4];
      _componentsB[5] = _componentsA[5];
    } else {
      Mat2D.copy(transformB, target.worldTransform);
      if (_sourceSpace == TransformSpace.Local) {
        ActorNode sourceGrandParent = target.parent;
        if (sourceGrandParent != null) {
          Mat2D inverse = Mat2D();
          if (!Mat2D.invert(inverse, sourceGrandParent.worldTransform)) {
            return;
          }
          Mat2D.multiply(transformB, inverse, transformB);
        }
      }
      Mat2D.decompose(transformB, _componentsB);

      if (!_copy) {
        _componentsB.rotation =
            _destSpace == TransformSpace.Local ? 1.0 : _componentsA.rotation;
      } else {
        _componentsB.rotation *= _scale;
        if (_offset) {
          _componentsB.rotation += parent.rotation;
        }
      }

      if (_destSpace == TransformSpace.Local) {
        // Destination space is in parent transform coordinates.
        // Recompose the parent local transform and get it in world, then decompose the world for interpolation.
        if (grandParent != null) {
          Mat2D.compose(transformB, _componentsB);
          Mat2D.multiply(transformB, grandParent.worldTransform, transformB);
          Mat2D.decompose(transformB, _componentsB);
        }
      }
    }

    bool clampLocal =
        _minMaxSpace == TransformSpace.Local && grandParent != null;
    if (clampLocal) {
      // Apply min max in local space, so transform to local coordinates first.
      Mat2D.compose(transformB, _componentsB);
      Mat2D inverse = Mat2D();
      if (!Mat2D.invert(inverse, grandParent.worldTransform)) {
        return;
      }
      Mat2D.multiply(transformB, inverse, transformB);
      Mat2D.decompose(transformB, _componentsB);
    }
    if (_enableMax && _componentsB.rotation > _max) {
      _componentsB.rotation = _max;
    }
    if (_enableMin && _componentsB.rotation < _min) {
      _componentsB.rotation = _min;
    }
    if (clampLocal) {
      // Transform back to world.
      Mat2D.compose(transformB, _componentsB);
      Mat2D.multiply(transformB, grandParent.worldTransform, transformB);
      Mat2D.decompose(transformB, _componentsB);
    }

    double angleA = _componentsA.rotation % PI2;
    double angleB = _componentsB.rotation % PI2;
    double diff = angleB - angleA;

    if (diff > pi) {
      diff -= PI2;
    } else if (diff < -pi) {
      diff += PI2;
    }
    _componentsB.rotation = _componentsA.rotation + diff * strength;
    _componentsB.x = _componentsA.x;
    _componentsB.y = _componentsA.y;
    _componentsB.scaleX = _componentsA.scaleX;
    _componentsB.scaleY = _componentsA.scaleY;
    _componentsB.skew = _componentsA.skew;

    Mat2D.compose(parent.worldTransform, _componentsB);
  }

  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    ActorRotationConstraint instance = ActorRotationConstraint();
    instance.copyRotationConstraint(this, resetArtboard);
    return instance;
  }

  void copyRotationConstraint(
      ActorRotationConstraint node, ActorArtboard resetArtboard) {
    copyTargetedConstraint(node, resetArtboard);

    _copy = node._copy;
    _scale = node._scale;
    _enableMin = node._enableMin;
    _enableMax = node._enableMax;
    _min = node._min;
    _max = node._max;

    _offset = node._offset;
    _sourceSpace = node._sourceSpace;
    _destSpace = node._destSpace;
    _minMaxSpace = node._minMaxSpace;
  }

  void update(int dirt) {}
  void completeResolve() {}
}
