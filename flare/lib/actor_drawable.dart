import "actor.dart";
import "actor_node.dart";

enum BlendModes
{
	Normal,
	Multiply,
	Screen,
	Additive
}

class ActorDrawable extends ActorNode
{
	// Editor set draw index.
	int drawOrder = 0;
	// Computed draw index in the image list.
	int drawIndex = 0;
	BlendModes blendMode;

	void copyDrawable(ActorDrawable node, Actor resetActor)
	{
		copyNode(node, resetActor);

		drawOrder = node.drawOrder;
		blendMode = node.blendMode;
	}
}