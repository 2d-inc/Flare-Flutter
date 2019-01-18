import "stream_reader.dart";
import "actor_artboard.dart";
import "actor_bone_base.dart";
import "actor_component.dart";

class ActorJellyBone extends ActorBoneBase {
  ActorComponent makeInstance(ActorArtboard artboard) {
    ActorJellyBone instanceNode = ActorJellyBone();
    instanceNode.copyBoneBase(this, artboard);
    return instanceNode;
  }

  static ActorJellyBone read(
      ActorArtboard artboard, StreamReader reader, ActorJellyBone node) {
    if (node == null) {
      node = ActorJellyBone();
    }

    // The Jelly Bone has a specialized read that doesn't go down the typical node path, this is because majority of the transform properties
    // of the Jelly Bone are controlled by the Jelly Controller and are unnecessary for serialization.
    ActorComponent.read(artboard, reader, node);
    node.opacity = reader.readFloat32("opacity");
    node.collapsedVisibility = reader.readBool("isCollapsed");
    return node;
  }
}
