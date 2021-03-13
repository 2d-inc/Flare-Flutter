import 'package:flare_flutter/base/actor_artboard.dart';
import 'package:flare_flutter/base/actor_bone.dart';
import 'package:flare_flutter/base/actor_component.dart';
import 'package:flare_flutter/base/actor_node.dart';
import 'package:flare_flutter/base/stream_reader.dart';

class ActorRootBone extends ActorNode {
  ActorBone? _firstBone;

  ActorBone? get firstBone {
    return _firstBone;
  }

  @override
  void completeResolve() {
    super.completeResolve();
    if (children == null) {
      return;
    }
    for (final ActorComponent component in children!) {
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

  // ignore: prefer_constructors_over_static_methods
  static ActorRootBone read(
      ActorArtboard artboard, StreamReader reader, ActorRootBone? node) {
    // ignore: parameter_assignments
    node ??= ActorRootBone();
    ActorNode.read(artboard, reader, node);
    return node;
  }
}
