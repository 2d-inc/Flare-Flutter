import 'package:flare_flutter/base/actor_artboard.dart';
import 'package:flare_flutter/base/actor_axis_constraint.dart';
import 'package:flare_flutter/base/actor_component.dart';
import 'package:flare_flutter/base/actor_node.dart';
import 'package:flare_flutter/base/math/mat2d.dart';
import 'package:flare_flutter/base/math/vec2d.dart';
import 'package:flare_flutter/base/stream_reader.dart';
import 'package:flare_flutter/base/transform_space.dart';

class ActorTranslationConstraint extends ActorAxisConstraint {
  ActorTranslationConstraint() : super();

  // ignore: prefer_constructors_over_static_methods
  @override
  void completeResolve() {}

  @override
  void constrain(ActorNode node) {
    ActorNode? t = target as ActorNode?;
    ActorNode p = parent!;
    ActorNode? grandParent = p.parent;

    Mat2D transformA = parent!.worldTransform;
    Vec2D translationA = Vec2D.fromValues(transformA[4], transformA[5]);
    Vec2D translationB = Vec2D();

    if (t == null) {
      Vec2D.copy(translationB, translationA);
    } else {
      Mat2D transformB = Mat2D.clone(t.worldTransform);
      if (sourceSpace == TransformSpace.local) {
        ActorNode? sourceGrandParent = t.parent;
        if (sourceGrandParent != null) {
          Mat2D inverse = Mat2D();
          Mat2D.invert(inverse, sourceGrandParent.worldTransform);
          Mat2D.multiply(transformB, inverse, transformB);
        }
      }
      translationB[0] = transformB[4];
      translationB[1] = transformB[5];

      if (!copyX) {
        translationB[0] =
            destSpace == TransformSpace.local ? 0.0 : translationA[0];
      } else {
        translationB[0] *= scaleX;
        if (offset) {
          translationB[0] += parent!.translation[0];
        }
      }

      if (!copyY) {
        translationB[1] =
            destSpace == TransformSpace.local ? 0.0 : translationA[1];
      } else {
        translationB[1] *= scaleY;
        if (offset) {
          translationB[1] += parent!.translation[1];
        }
      }

      if (destSpace == TransformSpace.local) {
        if (grandParent != null) {
          Vec2D.transformMat2D(
              translationB, translationB, grandParent.worldTransform);
        }
      }
    }

    bool clampLocal =
        minMaxSpace == TransformSpace.local && grandParent != null;
    if (clampLocal) {
      // Apply min max in local space, so transform to local coordinates first.
      Mat2D temp = Mat2D();
      Mat2D.invert(temp, grandParent.worldTransform);
      // Get our target world coordinates in parent local.
      Vec2D.transformMat2D(translationB, translationB, temp);
    }
    if (enableMaxX && translationB[0] > maxX) {
      translationB[0] = maxX;
    }
    if (enableMinX && translationB[0] < minX) {
      translationB[0] = minX;
    }
    if (enableMaxY && translationB[1] > maxY) {
      translationB[1] = maxY;
    }
    if (enableMinY && translationB[1] < minY) {
      translationB[1] = minY;
    }
    if (clampLocal) {
      // Transform back to world.
      Vec2D.transformMat2D(
          translationB, translationB, grandParent.worldTransform);
    }

    double ti = 1.0 - strength;

    // Just interpolate world translation
    transformA[4] = translationA[0] * ti + translationB[0] * strength;
    transformA[5] = translationA[1] * ti + translationB[1] * strength;
  }

  @override
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    ActorTranslationConstraint node = ActorTranslationConstraint();
    node.copyAxisConstraint(this, resetArtboard);
    return node;
  }

  @override
  void update(int dirt) {}
  // ignore: prefer_constructors_over_static_methods
  static ActorTranslationConstraint read(ActorArtboard artboard,
      StreamReader reader, ActorTranslationConstraint? component) {
    // ignore: parameter_assignments
    component ??= ActorTranslationConstraint();
    ActorAxisConstraint.read(artboard, reader, component);

    return component;
  }
}
