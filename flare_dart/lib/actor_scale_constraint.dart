import "actor_artboard.dart";
import "actor_node.dart";
import "stream_reader.dart";
import "actor_axis_constraint.dart";
import "math/mat2d.dart";
import "math/transform_components.dart";
import "transform_space.dart";

class ActorScaleConstraint extends ActorAxisConstraint {
  TransformComponents _componentsA = TransformComponents();
  TransformComponents _componentsB = TransformComponents();

  ActorScaleConstraint() : super();

  static ActorScaleConstraint read(ActorArtboard artboard, StreamReader reader,
      ActorScaleConstraint component) {
    if (component == null) {
      component = ActorScaleConstraint();
    }
    ActorAxisConstraint.read(artboard, reader, component);
    return component;
  }

  @override
  makeInstance(ActorArtboard resetArtboard) {
    ActorScaleConstraint node = ActorScaleConstraint();
    node.copyAxisConstraint(this, resetArtboard);
    return node;
  }

  @override
  constrain(ActorNode node) {
    ActorNode t = this.target;
    ActorNode p = this.parent;
    ActorNode grandParent = p.parent;

    Mat2D transformA = parent.worldTransform;
    Mat2D transformB = Mat2D();
    Mat2D.decompose(transformA, _componentsA);
    if (t == null) {
      Mat2D.copy(transformB, transformA);
      _componentsB[0] = _componentsA[0];
      _componentsB[1] = _componentsA[1];
      _componentsB[2] = _componentsA[2];
      _componentsB[3] = _componentsA[3];
      _componentsB[4] = _componentsA[4];
      _componentsB[5] = _componentsA[5];
    } else {
      Mat2D.copy(transformB, t.worldTransform);
      if (sourceSpace == TransformSpace.Local) {
        ActorNode sourceGrandParent = t.parent;
        if (sourceGrandParent != null) {
          Mat2D inverse = Mat2D();
          Mat2D.invert(inverse, sourceGrandParent.worldTransform);
          Mat2D.multiply(transformB, inverse, transformB);
        }
      }
      Mat2D.decompose(transformB, _componentsB);

      if (!this.copyX) {
        _componentsB[2] =
            this.destSpace == TransformSpace.Local ? 1.0 : _componentsA[2];
      } else {
        _componentsB[2] *= this.scaleX;
        if (this.offset) {
          _componentsB[2] *= parent.scaleX;
        }
      }

      if (!this.copyY) {
        _componentsB[3] =
            this.destSpace == TransformSpace.Local ? 0.0 : _componentsA[3];
      } else {
        _componentsB[3] *= this.scaleY;

        if (this.offset) {
          _componentsB[3] *= parent.scaleY;
        }
      }

      if (destSpace == TransformSpace.Local) {
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
        (minMaxSpace == TransformSpace.Local && grandParent != null);
    if (clampLocal) {
      // Apply min max in local space, so transform to local coordinates first.
      Mat2D.compose(transformB, _componentsB);
      Mat2D inverse = Mat2D();
      Mat2D.invert(inverse, grandParent.worldTransform);
      Mat2D.multiply(transformB, inverse, transformB);
      Mat2D.decompose(transformB, _componentsB);
    }
    if (this.enableMaxX && _componentsB[2] > this.maxX) {
      _componentsB[2] = this.maxX;
    }
    if (this.enableMinX && _componentsB[2] < this.minX) {
      _componentsB[2] = this.minX;
    }
    if (this.enableMaxY && _componentsB[3] > this.maxY) {
      _componentsB[3] = this.maxY;
    }
    if (this.enableMinY && _componentsB[3] < this.minY) {
      _componentsB[3] = this.minY;
    }
    if (clampLocal) {
      // Transform back to world.
      Mat2D.compose(transformB, _componentsB);
      Mat2D.multiply(transformB, grandParent.worldTransform, transformB);
      Mat2D.decompose(transformB, _componentsB);
    }

    double ti = 1.0 - this.strength;

    _componentsB[4] = _componentsA[4];
    _componentsB[0] = _componentsA[0];
    _componentsB[1] = _componentsA[1];
    _componentsB[2] = _componentsA[2] * ti + _componentsB[2] * this.strength;
    _componentsB[3] = _componentsA[3] * ti + _componentsB[3] * this.strength;
    _componentsB[5] = _componentsA[5];

    Mat2D.compose(parent.worldTransform, _componentsB);
  }

  @override
  void update(int dirt) {}
  @override
  void completeResolve() {}
}
