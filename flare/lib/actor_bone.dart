import "binary_reader.dart";
import "actor.dart";
import "actor_bone_base.dart";
import "actor_component.dart";
import "actor_node.dart";
import "jelly_component.dart";

class ActorBone extends ActorBoneBase
{
	ActorBone _firstBone;
	JellyComponent jelly;

	ActorBone get firstBone
	{
		return _firstBone;
	}

	ActorComponent makeInstance(Actor resetActor)
	{
		ActorBone instanceNode = new ActorBone();
		instanceNode.copyBoneBase(this, resetActor);
		return instanceNode;
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

	static ActorBone read(Actor actor, BinaryReader reader, ActorBone node)
	{
		if(node == null)
		{
			node = new ActorBone();
		}
		ActorBoneBase.read(actor, reader, node);
		return node;
	}
}