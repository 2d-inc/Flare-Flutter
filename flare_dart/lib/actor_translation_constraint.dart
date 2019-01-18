import "actor_artboard.dart";
import "actor_node.dart";
import "actor_axis_constraint.dart";
import "math/vec2d.dart";
import "math/mat2d.dart";
import "transform_space.dart";
import "stream_reader.dart";

class ActorTranslationConstraint extends ActorAxisConstraint {
  ActorTranslationConstraint() : super();

  static ActorTranslationConstraint read(ActorArtboard artboard,
      StreamReader reader, ActorTranslationConstraint component) {
    if (component == null) {
      component = ActorTranslationConstraint();
    }
    ActorAxisConstraint.read(artboard, reader, component);

    return component;
  }

  @override
  makeInstance(ActorArtboard resetArtboard) {
    ActorTranslationConstraint node = ActorTranslationConstraint();
    node.copyAxisConstraint(this, resetArtboard);
    return node;
  }

  @override
  constrain(ActorNode node) {
    ActorNode t = this.target;
    ActorNode p = this.parent;
    ActorNode grandParent = p.parent;

    Mat2D transformA = parent.worldTransform;
    Vec2D translationA = Vec2D.fromValues(transformA[4], transformA[5]);
    Vec2D translationB = Vec2D();

    if (t == null) {
      Vec2D.copy(translationB, translationA);
    } else {
      Mat2D transformB = Mat2D.clone(t.worldTransform);
      if (this.sourceSpace == TransformSpace.Local) {
        ActorNode sourceGrandParent = t.parent;
        if (sourceGrandParent != null) {
          Mat2D inverse = Mat2D();
          Mat2D.invert(inverse, sourceGrandParent.worldTransform);
          Mat2D.multiply(transformB, inverse, transformB);
        }
      }
      translationB[0] = transformB[4];
      translationB[1] = transformB[5];

      if (!this.copyX) {
        translationB[0] =
            destSpace == TransformSpace.Local ? 0.0 : translationA[0];
      } else {
        translationB[0] *= this.scaleX;
        if (this.offset) {
          translationB[0] += parent.translation[0];
        }
      }

      if (!this.copyY) {
        translationB[1] =
            destSpace == TransformSpace.Local ? 0.0 : translationA[1];
      } else {
        translationB[1] *= this.scaleY;
        if (this.offset) {
          translationB[1] += parent.translation[1];
        }
      }

      if (destSpace == TransformSpace.Local) {
        if (grandParent != null) {
          Vec2D.transformMat2D(
              translationB, translationB, grandParent.worldTransform);
        }
      }
    }

    bool clampLocal =
        (minMaxSpace == TransformSpace.Local && grandParent != null);
    if (clampLocal) {
      // Apply min max in local space, so transform to local coordinates first.
      Mat2D temp = Mat2D();
      Mat2D.invert(temp, grandParent.worldTransform);
      // Get our target world coordinates in parent local.
      Vec2D.transformMat2D(translationB, translationB, temp);
    }
    if (this.enableMaxX && translationB[0] > this.maxX) {
      translationB[0] = this.maxX;
    }
    if (this.enableMinX && translationB[0] < this.minX) {
      translationB[0] = this.minX;
    }
    if (this.enableMaxY && translationB[1] > this.maxY) {
      translationB[1] = this.maxY;
    }
    if (this.enableMinY && translationB[1] < this.minY) {
      translationB[1] = this.minY;
    }
    if (clampLocal) {
      // Transform back to world.
      Vec2D.transformMat2D(
          translationB, translationB, grandParent.worldTransform);
    }

    double ti = 1.0 - this.strength;

    // Just interpolate world translation
    transformA[4] = translationA[0] * ti + translationB[0] * this.strength;
    transformA[5] = translationA[1] * ti + translationB[1] * this.strength;
  }

  @override
  void update(int dirt) {}
  @override
  void completeResolve() {}
}
