import 'package:flare_flutter/base/actor_artboard.dart';
import 'package:flare_flutter/base/actor_bone_base.dart';
import 'package:flare_flutter/base/actor_component.dart';
import 'package:flare_flutter/base/stream_reader.dart';

class ActorJellyBone extends ActorBoneBase {
  @override
  ActorComponent makeInstance(ActorArtboard artboard) {
    ActorJellyBone instanceNode = ActorJellyBone();
    instanceNode.copyBoneBase(this, artboard);
    return instanceNode;
  }

  // ignore: prefer_constructors_over_static_methods
  static ActorJellyBone read(
      ActorArtboard artboard, StreamReader reader, ActorJellyBone? node) {
    // ignore: parameter_assignments
    node ??= ActorJellyBone();

    // The Jelly Bone has a specialized read that doesn't go down the typical
    // node path, this is because majority of the transform properties
    // of the Jelly Bone are controlled by the Jelly Controller and are
    // unnecessary for serialization.
    ActorComponent.read(artboard, reader, node);
    node.opacity = reader.readFloat32('opacity');
    node.collapsedVisibility = reader.readBool('isCollapsed');
    return node;
  }
}
