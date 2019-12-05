import "actor_artboard.dart";
import "actor_bone_base.dart";
import "actor_component.dart";
import "jelly_component.dart";
import "stream_reader.dart";

class ActorBone extends ActorBoneBase {
  ActorBone _firstBone;
  JellyComponent jelly;

  ActorBone get firstBone {
    return _firstBone;
  }

  @override
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    ActorBone instanceNode = ActorBone();
    instanceNode.copyBoneBase(this, resetArtboard);
    return instanceNode;
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

  static ActorBone read(
      ActorArtboard artboard, StreamReader reader, ActorBone node) {
    node ??= ActorBone();
    ActorBoneBase.read(artboard, reader, node);
    return node;
  }
}
