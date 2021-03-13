import 'dart:math';

import 'package:flare_flutter/base/actor_artboard.dart';
import 'package:flare_flutter/base/actor_component.dart';
import 'package:flare_flutter/base/actor_node.dart';
import 'package:flare_flutter/base/actor_targeted_constraint.dart';
import 'package:flare_flutter/base/math/mat2d.dart';
import 'package:flare_flutter/base/math/transform_components.dart';
import 'package:flare_flutter/base/stream_reader.dart';
import 'package:flare_flutter/base/transform_space.dart';

const pi2 = pi * 2;

class ActorTransformConstraint extends ActorTargetedConstraint {
  int _sourceSpace = TransformSpace.world;
  int _destSpace = TransformSpace.world;
  final TransformComponents _componentsA = TransformComponents();
  final TransformComponents _componentsB = TransformComponents();

  ActorTransformConstraint() : super();

  // ignore: prefer_constructors_over_static_methods
  @override
  void completeResolve() {}

  @override
  void constrain(ActorNode node) {
    ActorNode? t = target as ActorNode?;
    if (t == null) {
      return;
    }

    ActorNode parent = this.parent!;

    Mat2D transformA = parent.worldTransform;
    Mat2D transformB = Mat2D.clone(t.worldTransform);
    if (_sourceSpace == TransformSpace.local) {
      ActorNode? grandParent = target!.parent;
      if (grandParent != null) {
        Mat2D inverse = Mat2D();
        Mat2D.invert(inverse, grandParent.worldTransform);
        Mat2D.multiply(transformB, inverse, transformB);
      }
    }
    if (_destSpace == TransformSpace.local) {
      ActorNode? grandParent = parent.parent;
      if (grandParent != null) {
        Mat2D.multiply(transformB, grandParent.worldTransform, transformB);
      }
    }
    Mat2D.decompose(transformA, _componentsA);
    Mat2D.decompose(transformB, _componentsB);

    double angleA = _componentsA[4] % pi2;
    double angleB = _componentsB[4] % pi2;
    double diff = angleB - angleA;
    if (diff > pi) {
      diff -= pi2;
    } else if (diff < -pi) {
      diff += pi2;
    }

    double ti = 1.0 - strength;

    _componentsB[4] = angleA + diff * strength;
    _componentsB[0] = _componentsA[0] * ti + _componentsB[0] * strength;
    _componentsB[1] = _componentsA[1] * ti + _componentsB[1] * strength;
    _componentsB[2] = _componentsA[2] * ti + _componentsB[2] * strength;
    _componentsB[3] = _componentsA[3] * ti + _componentsB[3] * strength;
    _componentsB[5] = _componentsA[5] * ti + _componentsB[5] * strength;

    Mat2D.compose(parent.worldTransform, _componentsB);
  }

  void copyTransformConstraint(
      ActorTransformConstraint node, ActorArtboard resetArtboard) {
    copyTargetedConstraint(node, resetArtboard);
    _sourceSpace = node._sourceSpace;
    _destSpace = node._destSpace;
  }

  @override
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    ActorTransformConstraint node = ActorTransformConstraint();
    node.copyTransformConstraint(this, resetArtboard);
    return node;
  }

  @override
  void update(int dirt) {}
  // ignore: prefer_constructors_over_static_methods
  static ActorTransformConstraint read(ActorArtboard artboard,
      StreamReader reader, ActorTransformConstraint? component) {
    // ignore: parameter_assignments
    component ??= ActorTransformConstraint();
    ActorTargetedConstraint.read(artboard, reader, component);

    component._sourceSpace = reader.readUint8('sourceSpaceId');
    component._destSpace = reader.readUint8('destSpaceId');

    return component;
  }
}
