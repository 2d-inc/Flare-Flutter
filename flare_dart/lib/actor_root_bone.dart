import "stream_reader.dart";
import "actor_artboard.dart";
import "actor_node.dart";
import "actor_bone.dart";
import "actor_component.dart";

class ActorRootBone extends ActorNode {
  ActorBone _firstBone;

  ActorBone get firstBone {
    return _firstBone;
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

  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    ActorRootBone instanceNode = ActorRootBone();
    instanceNode.copyNode(this, resetArtboard);
    return instanceNode;
  }

  static ActorRootBone read(
      ActorArtboard artboard, StreamReader reader, ActorRootBone node) {
    if (node == null) {
      node = ActorRootBone();
    }
    ActorNode.read(artboard, reader, node);
    return node;
  }
}
