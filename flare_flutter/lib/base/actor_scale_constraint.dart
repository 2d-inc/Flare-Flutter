import 'package:flare_flutter/base/actor_artboard.dart';
import 'package:flare_flutter/base/actor_axis_constraint.dart';
import 'package:flare_flutter/base/actor_component.dart';
import 'package:flare_flutter/base/actor_node.dart';
import 'package:flare_flutter/base/math/mat2d.dart';
import 'package:flare_flutter/base/math/transform_components.dart';
import 'package:flare_flutter/base/stream_reader.dart';
import 'package:flare_flutter/base/transform_space.dart';

class ActorScaleConstraint extends ActorAxisConstraint {
  final TransformComponents _componentsA = TransformComponents();
  final TransformComponents _componentsB = TransformComponents();

  ActorScaleConstraint() : super();

  // ignore: prefer_constructors_over_static_methods
  @override
  void completeResolve() {}

  @override
  void constrain(ActorNode node) {
    ActorNode? t = target as ActorNode?;
    ActorNode p = parent!;
    ActorNode? grandParent = p.parent;

    Mat2D transformA = parent!.worldTransform;
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
      if (sourceSpace == TransformSpace.local) {
        ActorNode? sourceGrandParent = t.parent;
        if (sourceGrandParent != null) {
          Mat2D inverse = Mat2D();
          Mat2D.invert(inverse, sourceGrandParent.worldTransform);
          Mat2D.multiply(transformB, inverse, transformB);
        }
      }
      Mat2D.decompose(transformB, _componentsB);

      if (!copyX) {
        _componentsB[2] =
            destSpace == TransformSpace.local ? 1.0 : _componentsA[2];
      } else {
        _componentsB[2] *= scaleX;
        if (offset) {
          _componentsB[2] *= parent!.scaleX;
        }
      }

      if (!copyY) {
        _componentsB[3] =
            destSpace == TransformSpace.local ? 0.0 : _componentsA[3];
      } else {
        _componentsB[3] *= scaleY;

        if (offset) {
          _componentsB[3] *= parent!.scaleY;
        }
      }

      if (destSpace == TransformSpace.local) {
        // Destination space is in parent transform coordinates.
        // Recompose the parent local transform and get it in world,
        // then decompose the world for interpolation.
        if (grandParent != null) {
          Mat2D.compose(transformB, _componentsB);
          Mat2D.multiply(transformB, grandParent.worldTransform, transformB);
          Mat2D.decompose(transformB, _componentsB);
        }
      }
    }

    bool clampLocal =
        minMaxSpace == TransformSpace.local && grandParent != null;
    if (clampLocal) {
      // Apply min max in local space, so transform to local coordinates first.
      Mat2D.compose(transformB, _componentsB);
      Mat2D inverse = Mat2D();
      Mat2D.invert(inverse, grandParent.worldTransform);
      Mat2D.multiply(transformB, inverse, transformB);
      Mat2D.decompose(transformB, _componentsB);
    }
    if (enableMaxX && _componentsB[2] > maxX) {
      _componentsB[2] = maxX;
    }
    if (enableMinX && _componentsB[2] < minX) {
      _componentsB[2] = minX;
    }
    if (enableMaxY && _componentsB[3] > maxY) {
      _componentsB[3] = maxY;
    }
    if (enableMinY && _componentsB[3] < minY) {
      _componentsB[3] = minY;
    }
    if (clampLocal) {
      // Transform back to world.
      Mat2D.compose(transformB, _componentsB);
      Mat2D.multiply(transformB, grandParent.worldTransform, transformB);
      Mat2D.decompose(transformB, _componentsB);
    }

    double ti = 1.0 - strength;

    _componentsB[4] = _componentsA[4];
    _componentsB[0] = _componentsA[0];
    _componentsB[1] = _componentsA[1];
    _componentsB[2] = _componentsA[2] * ti + _componentsB[2] * strength;
    _componentsB[3] = _componentsA[3] * ti + _componentsB[3] * strength;
    _componentsB[5] = _componentsA[5];

    Mat2D.compose(parent!.worldTransform, _componentsB);
  }

  @override
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    ActorScaleConstraint node = ActorScaleConstraint();
    node.copyAxisConstraint(this, resetArtboard);
    return node;
  }

  @override
  void update(int dirt) {}
  // ignore: prefer_constructors_over_static_methods
  static ActorScaleConstraint read(ActorArtboard artboard, StreamReader reader,
      ActorScaleConstraint? component) {
    // ignore: parameter_assignments
    component ??= ActorScaleConstraint();
    ActorAxisConstraint.read(artboard, reader, component);
    return component;
  }
}
