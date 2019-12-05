import "actor_artboard.dart";
import "actor_bone.dart";
import "actor_component.dart";
import "actor_node.dart";
import "stream_reader.dart";

class ActorRootBone extends ActorNode {
  ActorBone _firstBone;

  ActorBone get firstBone {
    return _firstBone;
  }

  @override
  void completeResolve() {
    super.completeResolve();
    if (children == null) {
      return;
    }
    for (final ActorComponent component in children) {
      if (component is ActorBone) {
        _firstBone = component;
        return;
      }
    }
  }

  @override
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    ActorRootBone instanceNode = ActorRootBone();
    instanceNode.copyNode(this, resetArtboard);
    return instanceNode;
  }

  static ActorRootBone read(
      ActorArtboard artboard, StreamReader reader, ActorRootBone node) {
    node ??= ActorRootBone();
    ActorNode.read(artboard, reader, node);
    return node;
  }
}
