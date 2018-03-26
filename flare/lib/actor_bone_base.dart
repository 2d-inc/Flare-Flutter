import "binary_reader.dart";
import "actor.dart";
import "actor_node.dart";
import "math/vec2d.dart";
import "math/mat2d.dart";

class ActorBoneBase extends ActorNode
{
	double _length;
	bool isConnectedToImage;

	double get length
	{
		return _length;
	}

	set length(double value)
	{
		if(_length == value)
		{
			return;
		}
		_length = value;
		if(children == null)
		{
			return;
		}
		for(ActorNode node in children)
		{
			ActorBoneBase bone = node as ActorBoneBase;
			if(bone == null)
			{
				continue;
			}
			bone.x = value;
		}
	}

	Vec2D getTipWorldTranslation(Vec2D vec)
	{
		Mat2D transform = new Mat2D();
		transform[4] = _length;
		Mat2D.multiply(transform, worldTransform, transform);
		vec[0] = transform[4];
		vec[1] = transform[5];
		return vec;
	}

	static ActorBoneBase read(Actor actor, BinaryReader reader, ActorBoneBase node)
	{
		ActorNode.read(actor, reader, node);

		node._length = reader.readFloat32();

		return node;
	}

	void copyBoneBase(ActorBoneBase node, Actor resetActor)
	{
		super.copyNode(node, resetActor);
		_length = node._length;
		isConnectedToImage = node.isConnectedToImage;
	}
}