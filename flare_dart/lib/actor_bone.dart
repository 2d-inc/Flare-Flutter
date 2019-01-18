import "stream_reader.dart";
import "actor_artboard.dart";
import "actor_bone_base.dart";
import "actor_component.dart";
import "actor_node.dart";
import "jelly_component.dart";

class ActorBone extends ActorBoneBase {
  ActorBone _firstBone;
  JellyComponent jelly;

  ActorBone get firstBone {
    return _firstBone;
  }

  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    ActorBone instanceNode = ActorBone();
    instanceNode.copyBoneBase(this, resetArtboard);
    return instanceNode;
  }

  void completeResolve() {
    super.completeResolve();
    if (children == null) {
      return;
    }
    for (ActorNode node in children) {
      if (node is ActorBone) {
        _firstBone = node;
        return;
      }
    }
  }

  static ActorBone read(
      ActorArtboard artboard, StreamReader reader, ActorBone node) {
    if (node == null) {
      node = ActorBone();
    }
    ActorBoneBase.read(artboard, reader, node);
    return node;
  }
}
