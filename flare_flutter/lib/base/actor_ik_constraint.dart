import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flare_flutter/base/actor_artboard.dart';
import 'package:flare_flutter/base/actor_bone.dart';
import 'package:flare_flutter/base/actor_component.dart';
import 'package:flare_flutter/base/actor_node.dart';
import 'package:flare_flutter/base/actor_targeted_constraint.dart';
import 'package:flare_flutter/base/math/mat2d.dart';
import 'package:flare_flutter/base/math/transform_components.dart';
import 'package:flare_flutter/base/math/vec2d.dart';
import 'package:flare_flutter/base/stream_reader.dart';

class ActorIKConstraint extends ActorTargetedConstraint {
  static const double pi2 = pi * 2.0;
  bool _invertDirection = false;
  List<InfluencedBone>? _influencedBones;
  late List<BoneChain> _fkChain;
  late List<BoneChain> _boneData;

  @override
  void completeResolve() {
    if (_influencedBones == null || _influencedBones!.isEmpty) {
      return;
    }

    // Initialize solver.
    ActorBone start = _influencedBones![0].bone;
    ActorNode? end = _influencedBones![_influencedBones!.length - 1].bone;
    _fkChain = <BoneChain>[];
    while (end != null && end != start.parent) {
      BoneChain bc = BoneChain(
        idx,
        end as ActorBone,
        0.0,
        false, // initialize to false and correct to true later if length < 3.
        TransformComponents(),
        Mat2D(),
      );
      _fkChain.add(bc);
      end = end.parent;
    }
    bool allIn = _fkChain.length < 3;
    if (allIn) {
      for (final bc in _fkChain) {
        bc.included = true;
      }
    }
    _fkChain = _fkChain.reversed.toList();

    // Make sure bones are good.
    _boneData = <BoneChain>[];
    for (final InfluencedBone bone in _influencedBones!) {
      BoneChain? item =
          _fkChain.firstWhereOrNull((chainItem) => chainItem.bone == bone.bone);
      if (item == null) {
        print('Bone not in chain: ' + bone.bone.name);
        continue;
      }
      _boneData.add(item);
    }
    if (!allIn) {
      // Influenced bones are in the IK chain.
      for (int i = 0; i < _boneData.length - 1; i++) {
        BoneChain item = _boneData[i];
        item.included = true;
        _fkChain[item.index + 1].included = true;
      }
    }

    // Finally mark dependencies.
    for (final InfluencedBone bone in _influencedBones!) {
      // Don't mark dependency on parent as ActorComponent already does this.
      if (bone.bone == parent) {
        continue;
      }

      artboard.addDependency(this, bone.bone);
    }

    if (target != null) {
      artboard.addDependency(this, target!);
    }

    // All the first level children of the influenced bones should
    // depend on the final bone.
    BoneChain tip = _fkChain[_fkChain.length - 1];
    for (final BoneChain fk in _fkChain) {
      if (fk == tip) {
        continue;
      }

      ActorBone bone = fk.bone;
      for (final node in bone.children!) {
        BoneChain? item =
            _fkChain.firstWhereOrNull((chainItem) => chainItem.bone == node);
        if (item != null) {
          // node is in the FK chain.
          continue;
        }
        artboard.addDependency(node, tip.bone);
      }
    }
  }

  @override
  void constrain(ActorNode node) {
    ActorNode? target = this.target as ActorNode?;
    if (target == null) {
      return;
    }
    Vec2D worldTargetTranslation = Vec2D();
    target.getWorldTranslation(worldTargetTranslation);

    if (_influencedBones!.isEmpty) {
      return;
    }

    // Decompose the chain.
    for (final BoneChain item in _fkChain) {
      ActorBone bone = item.bone;
      Mat2D parentWorld = bone.parent!.worldTransform;
      Mat2D.invert(item.parentWorldInverse, parentWorld);
      Mat2D.multiply(
          bone.transform, item.parentWorldInverse, bone.worldTransform);
      Mat2D.decompose(bone.transform, item.transformComponents);
    }

    int count = _boneData.length;
    if (count == 1) {
      solve1(_boneData[0], worldTargetTranslation);
    } else if (count == 2) {
      solve2(_boneData[0], _boneData[1], worldTargetTranslation);
    } else {
      BoneChain tip = _boneData[count - 1];
      for (int i = 0; i < count - 1; i++) {
        BoneChain item = _boneData[i];
        solve2(item, tip, worldTargetTranslation);
        for (int j = item.index + 1; j < _fkChain.length - 1; j++) {
          BoneChain fk = _fkChain[j];
          Mat2D.invert(fk.parentWorldInverse, fk.bone.parent!.worldTransform);
        }
      }
    }

    // At the end, mix the FK angle with the IK angle by strength
    if (strength != 1.0) {
      for (final BoneChain fk in _fkChain) {
        if (!fk.included) {
          ActorBone bone = fk.bone;
          Mat2D.multiply(
              bone.worldTransform, bone.parent!.worldTransform, bone.transform);
          continue;
        }
        double fromAngle = fk.transformComponents.rotation % pi2;
        double toAngle = fk.angle % pi2;
        double diff = toAngle - fromAngle;
        if (diff > pi) {
          diff -= pi2;
        } else if (diff < -pi) {
          diff += pi2;
        }
        double angle = fromAngle + diff * strength;
        constrainRotation(fk, angle);
      }
    }
  }

  void constrainRotation(BoneChain fk, double rotation) {
    ActorBone bone = fk.bone;
    Mat2D parentWorld = bone.parent!.worldTransform;
    Mat2D transform = bone.transform;
    TransformComponents c = fk.transformComponents;

    if (rotation == 0.0) {
      Mat2D.identity(transform);
    } else {
      Mat2D.fromRotation(transform, rotation);
    }
    // Translate
    transform[4] = c.x;
    transform[5] = c.y;
    // Scale
    double scaleX = c.scaleX;
    double scaleY = c.scaleY;
    transform[0] *= scaleX;
    transform[1] *= scaleX;
    transform[2] *= scaleY;
    transform[3] *= scaleY;
    // Skew
    double skew = c.skew;
    if (skew != 0.0) {
      transform[2] = transform[0] * skew + transform[2];
      transform[3] = transform[1] * skew + transform[3];
    }

    Mat2D.multiply(bone.worldTransform, parentWorld, transform);
  }

  void copyIKConstraint(ActorIKConstraint node, ActorArtboard artboard) {
    copyTargetedConstraint(node, artboard);

    _invertDirection = node._invertDirection;
    if (node._influencedBones != null) {
      _influencedBones = <InfluencedBone>[];
      for (int i = 0; i < _influencedBones!.length; i++) {
        _influencedBones!
            .add(InfluencedBone(node._influencedBones![i].boneIdx));
      }
    }
  }

  @override
  ActorComponent makeInstance(ActorArtboard artboard) {
    ActorIKConstraint instance = ActorIKConstraint();
    instance.copyIKConstraint(this, artboard);
    return instance;
  }

  @override
  void resolveComponentIndices(List<ActorComponent?> components) {
    super.resolveComponentIndices(components);

    if (_influencedBones != null) {
      for (final InfluencedBone influenced in _influencedBones!) {
        influenced.bone = components[influenced.boneIdx]! as ActorBone;
        // Mark peer constraints, N.B. that we're not adding it to the
        //  parent bone as we're constraining it anyway.
        if (influenced.bone != parent) {
          influenced.bone.addPeerConstraint(this);
        }
      }
    }
  }

  void solve1(BoneChain fk1, Vec2D worldTargetTranslation) {
    Mat2D iworld = fk1.parentWorldInverse;
    var pA = Vec2D();
    fk1.bone.getWorldTranslation(pA);
    var pBT = Vec2D.clone(worldTargetTranslation);

    // To target in worldspace
    Vec2D toTarget = Vec2D.subtract(Vec2D(), pBT, pA);
    // Note this is directional, hence not transformMat2d
    Vec2D toTargetLocal = Vec2D.transformMat2(Vec2D(), toTarget, iworld);
    double r = atan2(toTargetLocal[1], toTargetLocal[0]);

    constrainRotation(fk1, r);
    fk1.angle = r;
  }

  void solve2(BoneChain fk1, BoneChain fk2, Vec2D worldTargetTranslation) {
    ActorBone b1 = fk1.bone;
    ActorBone b2 = fk2.bone;
    BoneChain firstChild = _fkChain[fk1.index + 1];

    Mat2D iworld = fk1.parentWorldInverse;

    Vec2D pA = b1.getWorldTranslation(Vec2D());
    Vec2D pC = firstChild.bone.getWorldTranslation(Vec2D());
    Vec2D pB = b2.getTipWorldTranslation(Vec2D());

    Vec2D pBT = Vec2D.clone(worldTargetTranslation);

    pA = Vec2D.transformMat2D(pA, pA, iworld);
    pC = Vec2D.transformMat2D(pC, pC, iworld);
    pB = Vec2D.transformMat2D(pB, pB, iworld);
    pBT = Vec2D.transformMat2D(pBT, pBT, iworld);

    // http://mathworld.wolfram.com/LawofCosines.html
    Vec2D av = Vec2D.subtract(Vec2D(), pB, pC);
    double a = Vec2D.length(av);

    Vec2D bv = Vec2D.subtract(Vec2D(), pC, pA);
    double b = Vec2D.length(bv);

    Vec2D cv = Vec2D.subtract(Vec2D(), pBT, pA);
    double c = Vec2D.length(cv);

    double A = acos(max(-1, min(1, (-a * a + b * b + c * c) / (2 * b * c))));
    double C = acos(max(-1, min(1, (a * a + b * b - c * c) / (2 * a * b))));

    double r1, r2;
    if (b2.parent != b1) {
      BoneChain secondChild = _fkChain[fk1.index + 2];

      Mat2D secondChildWorldInverse = secondChild.parentWorldInverse;

      pC = firstChild.bone.getWorldTranslation(Vec2D());
      pB = b2.getTipWorldTranslation(Vec2D());

      Vec2D avec = Vec2D.subtract(Vec2D(), pB, pC);
      Vec2D avLocal =
          Vec2D.transformMat2(Vec2D(), avec, secondChildWorldInverse);
      double angleCorrection = -atan2(avLocal[1], avLocal[0]);

      if (_invertDirection) {
        r1 = atan2(cv[1], cv[0]) - A;
        r2 = -C + pi + angleCorrection;
      } else {
        r1 = A + atan2(cv[1], cv[0]);
        r2 = C - pi + angleCorrection;
      }
    } else if (_invertDirection) {
      r1 = atan2(cv[1], cv[0]) - A;
      r2 = -C + pi;
    } else {
      r1 = A + atan2(cv[1], cv[0]);
      r2 = C - pi;
    }

    constrainRotation(fk1, r1);
    constrainRotation(firstChild, r2);
    if (firstChild != fk2) {
      ActorBone bone = fk2.bone;
      Mat2D.multiply(
          bone.worldTransform, bone.parent!.worldTransform, bone.transform);
    }

    // Simple storage, need this for interpolation.
    fk1.angle = r1;
    firstChild.angle = r2;
  }

  @override
  void update(int dirt) {}

  // ignore: prefer_constructors_over_static_methods
  static ActorIKConstraint read(ActorArtboard artboard, StreamReader reader,
      ActorIKConstraint? component) {
    // ignore: parameter_assignments
    component ??= ActorIKConstraint();
    ActorTargetedConstraint.read(artboard, reader, component);
    component._invertDirection = reader.readBool('isInverted');

    reader.openArray('bones');
    int numInfluencedBones = reader.readUint8Length();
    if (numInfluencedBones > 0) {
      component._influencedBones = <InfluencedBone>[];
      for (int i = 0; i < numInfluencedBones; i++) {
        // No label here, we're just clearing the elements from the array.
        component._influencedBones!.add(InfluencedBone(reader.readId('')));
      }
    }
    reader.closeArray();
    return component;
  }
}

class BoneChain {
  final int index;
  final ActorBone bone;
  double angle;
  bool included;
  final TransformComponents transformComponents;
  final Mat2D parentWorldInverse;

  BoneChain(
    this.index,
    this.bone,
    this.angle,
    this.included,
    this.transformComponents,
    this.parentWorldInverse,
  );
}

class InfluencedBone {
  final int boneIdx;
  late ActorBone bone;

  InfluencedBone(this.boneIdx);
}
