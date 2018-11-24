import "stream_reader.dart";
import "actor_artboard.dart";
import "math/mat2d.dart";
import "actor_node.dart";
import "actor_component.dart";

class SkinnedBone
{
	int boneIdx;
	ActorNode node;
	Mat2D bind = new Mat2D();
	Mat2D inverseBind = new Mat2D();
}

abstract class ActorSkinnable extends ActorNode
{
	List<SkinnedBone> _connectedBones;

	List<SkinnedBone> get connectedBones => _connectedBones;
	bool get isConnectedToBones => _connectedBones != null && _connectedBones.length > 0;

	static ActorSkinnable read(ActorArtboard artboard, StreamReader reader, ActorSkinnable node)
	{
		ActorNode.read(artboard, reader, node);

		reader.openArray("bones");
		int numConnectedBones = reader.readUint8Length();
		if(numConnectedBones != 0)
		{
			node._connectedBones = new List<SkinnedBone>(numConnectedBones);

			for(int i = 0; i < numConnectedBones; i++)
			{
				SkinnedBone bc = new SkinnedBone();
				reader.openObject("bone");
				bc.boneIdx = reader.readId("component");
				reader.readFloat32ArrayOffset(bc.bind.values, 6, 0, "bind");
				reader.closeObject();
				Mat2D.invert(bc.inverseBind, bc.bind);
				node._connectedBones[i] = bc;
			}
			reader.closeArray();
			Mat2D worldOverride = new Mat2D();
			reader.readFloat32ArrayOffset(worldOverride.values, 6, 0, "worldTransform");
			node.worldTransformOverride = worldOverride;
		}
		else
		{
			reader.closeArray();
		}

		return node;
	}

	void resolveComponentIndices(List<ActorComponent> components)
	{
		super.resolveComponentIndices(components);
		if(_connectedBones != null)
		{
			for(int i = 0; i < _connectedBones.length; i++)
			{
				SkinnedBone bc = _connectedBones[i];
				bc.node = components[bc.boneIdx] as ActorNode;
			}	
		}
	}

	void copySkinnable(ActorSkinnable node, ActorArtboard resetArtboard)
	{
		copyNode(node, resetArtboard);

		if(node._connectedBones != null)
		{
			_connectedBones = new List<SkinnedBone>(node._connectedBones.length);
			for(int i = 0; i < node._connectedBones.length; i++)
			{
				SkinnedBone from = node._connectedBones[i];
				SkinnedBone bc = new SkinnedBone();
				bc.boneIdx = from.boneIdx;
				Mat2D.copy(bc.bind, from.bind);
				Mat2D.copy(bc.inverseBind, from.inverseBind);
				_connectedBones[i] = bc;
			} 
		}
	}
}