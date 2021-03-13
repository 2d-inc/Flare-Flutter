import 'dart:typed_data';

import 'package:flare_flutter/base/actor_artboard.dart';
import 'package:flare_flutter/base/actor_component.dart';
import 'package:flare_flutter/base/actor_constraint.dart';
import 'package:flare_flutter/base/actor_skinnable.dart';
import 'package:flare_flutter/base/math/mat2d.dart';

class ActorSkin extends ActorComponent {
  Float32List _boneMatrices = Float32List(0);
  Float32List get boneMatrices => _boneMatrices;

  @override
  void completeResolve() {
    ActorSkinnable? skinnable = parent as ActorSkinnable?;
    if (skinnable == null) {
      return;
    }
    skinnable.skin = this;
    artboard.addDependency(this, skinnable as ActorComponent);
    if (skinnable.isConnectedToBones) {
      List<SkinnedBone> connectedBones = skinnable.connectedBones!;
      for (final SkinnedBone skinnedBone in connectedBones) {
        artboard.addDependency(this, skinnedBone.node);
        List<ActorConstraint> constraints = skinnedBone.node.allConstraints;

        for (final ActorConstraint constraint in constraints) {
          artboard.addDependency(this, constraint);
        }
      }
    }
  }

  @override
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    ActorSkin instance = ActorSkin();
    instance.copyComponent(this, resetArtboard);
    return instance;
  }

  @override
  void onDirty(int dirt) {
    // Intentionally empty. Doesn't throw dirt around.
  }

  @override
  void update(int dirt) {
    ActorSkinnable? skinnable = parent as ActorSkinnable?;
    if (skinnable == null) {
      return;
    }

    if (skinnable.isConnectedToBones) {
      List<SkinnedBone> connectedBones = skinnable.connectedBones!;
      int length = (connectedBones.length + 1) * 6;
      if (_boneMatrices.length != length) {
        _boneMatrices = Float32List(length);
        // First bone transform is always identity.
        _boneMatrices[0] = 1.0;
        _boneMatrices[1] = 0.0;
        _boneMatrices[2] = 0.0;
        _boneMatrices[3] = 1.0;
        _boneMatrices[4] = 0.0;
        _boneMatrices[5] = 0.0;
      }

      int bidx = 6; // Start after first identity.

      Mat2D mat = Mat2D();

      for (final SkinnedBone cb in connectedBones) {
        Mat2D.multiply(mat, cb.node.worldTransform, cb.inverseBind);

        _boneMatrices[bidx++] = mat[0];
        _boneMatrices[bidx++] = mat[1];
        _boneMatrices[bidx++] = mat[2];
        _boneMatrices[bidx++] = mat[3];
        _boneMatrices[bidx++] = mat[4];
        _boneMatrices[bidx++] = mat[5];
      }
    }

    skinnable.invalidateDrawable();
  }
}
