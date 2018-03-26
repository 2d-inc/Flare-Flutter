import "binary_reader.dart";
import "actor.dart";
import "actor_node.dart";
import "actor_component.dart";

class ActorRootBone extends ActorNode
{
	ActorComponent makeInstance(Actor resetActor)
	{
		ActorRootBone instanceNode = new ActorRootBone();
		instanceNode.copyNode(this, resetActor);
		return instanceNode;
	}

	static ActorRootBone read(Actor actor, BinaryReader reader, ActorRootBone node)
	{
		if(node == null)
		{
			node = new ActorRootBone();
		}
		ActorNode.read(actor, reader, node);
		return node;
	}
}