import "math/aabb.dart";

enum BlendModes
{
	Normal,
	Multiply,
	Screen,
	Additive
}

abstract class ActorDrawable
{
	// Editor set draw index.
	int get drawOrder;
	set drawOrder(int value);
	// Computed draw index in the draw list.
	int get drawIndex;
	set drawIndex(int value);
	
	AABB computeAABB();
}