import "stream_reader.dart";
import "actor.dart";
import "actor_node.dart";
import "actor_bone.dart";
import "actor_component.dart";

class ActorRootBone extends ActorNode
{
	ActorBone _firstBone;

	ActorBone get firstBone
	{
		return _firstBone;
	}

	void completeResolve()
	{
		super.completeResolve();
		if(children == null)
		{
			return;
		}
		for(ActorNode node in children)
		{
			if(node is ActorBone)
			{
				_firstBone = node;
				return;
			}
		}
	}

	ActorComponent makeInstance(Actor resetActor)
	{
		ActorRootBone instanceNode = new ActorRootBone();
		instanceNode.copyNode(this, resetActor);
		return instanceNode;
	}

	static ActorRootBone read(Actor actor, StreamReader reader, ActorRootBone node)
	{
		if(node == null)
		{
			node = new ActorRootBone();
		}
		ActorNode.read(actor, reader, node);
		return node;
	}
}