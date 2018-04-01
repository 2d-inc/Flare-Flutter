import "actor.dart";
import "actor_node.dart";
import "dart:typed_data";

enum BlendModes
{
	Normal,
	Multiply,
	Screen,
	Additive
}

abstract class ActorDrawable extends ActorNode
{
	// Editor set draw index.
	int drawOrder = 0;
	// Computed draw index in the image list.
	int drawIndex = 0;
	BlendModes blendMode;

	Float32List computeAABB();

	void copyDrawable(ActorDrawable node, Actor resetActor)
	{
		copyNode(node, resetActor);

		drawOrder = node.drawOrder;
		blendMode = node.blendMode;
	}
}