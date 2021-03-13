import 'package:flare_flutter/base/actor_artboard.dart';
import 'package:flare_flutter/base/actor_component.dart';
import 'package:flare_flutter/base/actor_node.dart';
import 'package:flare_flutter/base/actor_skin.dart';
import 'package:flare_flutter/base/math/mat2d.dart';
import 'package:flare_flutter/base/stream_reader.dart';

abstract class ActorSkinnable {
  ActorSkin? skin;
  List<SkinnedBone>? _connectedBones;
  List<SkinnedBone>? get connectedBones => _connectedBones;

  bool get isConnectedToBones =>
      _connectedBones != null && _connectedBones!.isNotEmpty;
  // ignore: avoid_setters_without_getters
  set worldTransformOverride(Mat2D? value);

  void copySkinnable(ActorSkinnable node, ActorArtboard resetArtboard) {
    if (node._connectedBones != null) {
      _connectedBones = <SkinnedBone>[];
      for (int i = 0; i < node._connectedBones!.length; i++) {
        SkinnedBone from = node._connectedBones![i];
        SkinnedBone bc = SkinnedBone(from.boneIdx);
        Mat2D.copy(bc.bind, from.bind);
        Mat2D.copy(bc.inverseBind, from.inverseBind);
        _connectedBones!.add(bc);
      }
    }
  }

  void invalidateDrawable();

  void resolveSkinnable(List<ActorComponent?> components) {
    if (_connectedBones != null) {
      // We still need to do _connectedBones! here. Why?
      for (int i = 0; i < _connectedBones!.length; i++) {
        SkinnedBone bc = _connectedBones![i];
        bc.node = components[bc.boneIdx]! as ActorNode;
      }
    }
  }

  static ActorSkinnable read(
      ActorArtboard artboard, StreamReader reader, ActorSkinnable node) {
    reader.openArray('bones');
    int numConnectedBones = reader.readUint8Length();
    if (numConnectedBones != 0) {
      node._connectedBones = <SkinnedBone>[];

      for (int i = 0; i < numConnectedBones; i++) {
        reader.openObject('bone');
        SkinnedBone bc = SkinnedBone(reader.readId('component'));
        Mat2D.copyFromList(bc.bind, reader.readFloat32Array(6, 'bind'));
        reader.closeObject();
        Mat2D.invert(bc.inverseBind, bc.bind);
        node._connectedBones!.add(bc);
      }
      reader.closeArray();
      Mat2D worldOverride = Mat2D();
      Mat2D.copyFromList(
          worldOverride, reader.readFloat32Array(6, 'worldTransform'));
      node.worldTransformOverride = worldOverride;
    } else {
      reader.closeArray();
    }

    return node;
  }
}

class SkinnedBone {
  final int boneIdx;
  late ActorNode node;
  final Mat2D bind = Mat2D();
  final Mat2D inverseBind = Mat2D();

  SkinnedBone(this.boneIdx);
}
