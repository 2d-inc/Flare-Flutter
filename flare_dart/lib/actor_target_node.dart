import 'actor_artboard.dart';
import 'actor_component.dart';
import 'actor_node.dart';

class ActorTargetNode extends ActorNode {
  @override
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    ActorTargetNode instanceNode = ActorTargetNode();
    instanceNode.copyNode(this, resetArtboard);
    return instanceNode;
  }
}
