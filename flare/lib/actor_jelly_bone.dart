import "binary_reader.dart";
import "actor.dart";
import "actor_bone_base.dart";
import "actor_component.dart";

class ActorJellyBone extends ActorBoneBase
{
	ActorComponent makeInstance(Actor resetActor)
	{
		ActorJellyBone instanceNode = new ActorJellyBone();
		instanceNode.copyBoneBase(this, resetActor);
		return instanceNode;
	}

	static ActorJellyBone read(Actor actor, BinaryReader reader, ActorJellyBone node)
	{
		if(node == null)
		{
			node = new ActorJellyBone();
		}

		// The Jelly Bone has a specialized read that doesn't go down the typical node path, this is because majority of the transform properties
		// of the Jelly Bone are controlled by the Jelly Controller and are unnecessary for serialization.
		ActorComponent.read(actor, reader, node);
		node.opacity = reader.readFloat32();
		node.collapsedVisibility = reader.readUint8() == 1;
		return node;
	}
}