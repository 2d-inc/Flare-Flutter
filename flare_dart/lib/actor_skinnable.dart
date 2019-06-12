import 'package:flare_dart/actor_skin.dart';

import "stream_reader.dart";
import "actor_artboard.dart";
import "math/mat2d.dart";
import "actor_node.dart";
import "actor_component.dart";

class SkinnedBone {
  int boneIdx;
  ActorNode node;
  Mat2D bind = Mat2D();
  Mat2D inverseBind = Mat2D();
}

abstract class ActorSkinnable {
  ActorSkin skin;
  List<SkinnedBone> _connectedBones;
  set worldTransformOverride(Mat2D value);

  List<SkinnedBone> get connectedBones => _connectedBones;
  bool get isConnectedToBones =>
      _connectedBones != null && _connectedBones.length > 0;

  static ActorSkinnable read(
      ActorArtboard artboard, StreamReader reader, ActorSkinnable node) {
    reader.openArray("bones");
    int numConnectedBones = reader.readUint8Length();
    if (numConnectedBones != 0) {
      node._connectedBones = List<SkinnedBone>(numConnectedBones);

      for (int i = 0; i < numConnectedBones; i++) {
        SkinnedBone bc = SkinnedBone();
        reader.openObject("bone");
        bc.boneIdx = reader.readId("component");
		Mat2D.copyFromList(bc.bind, reader.readFloat32Array(6, "bind"));
        reader.closeObject();
        Mat2D.invert(bc.inverseBind, bc.bind);
        node._connectedBones[i] = bc;
      }
      reader.closeArray();
      Mat2D worldOverride = Mat2D();
	  Mat2D.copyFromList(worldOverride, reader.readFloat32Array(6, "worldTransform"));
      node.worldTransformOverride = worldOverride;
    } else {
      reader.closeArray();
    }

    return node;
  }

  void resolveSkinnable(List<ActorComponent> components) {
    if (_connectedBones != null) {
      for (int i = 0; i < _connectedBones.length; i++) {
        SkinnedBone bc = _connectedBones[i];
        bc.node = components[bc.boneIdx] as ActorNode;
      }
    }
  }

  void copySkinnable(ActorSkinnable node, ActorArtboard resetArtboard) {
    if (node._connectedBones != null) {
      _connectedBones = List<SkinnedBone>(node._connectedBones.length);
      for (int i = 0; i < node._connectedBones.length; i++) {
        SkinnedBone from = node._connectedBones[i];
        SkinnedBone bc = SkinnedBone();
        bc.boneIdx = from.boneIdx;
        Mat2D.copy(bc.bind, from.bind);
        Mat2D.copy(bc.inverseBind, from.inverseBind);
        _connectedBones[i] = bc;
      }
    }
  }

  void invalidateDrawable();
}
