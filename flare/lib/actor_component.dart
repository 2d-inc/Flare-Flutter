import "binary_reader.dart";
import "actor.dart";
import "actor_node.dart";

abstract class ActorComponent
{
	String _name = "Unnamed";
	ActorNode parent;
	Actor actor;
	int _parentIdx = 0;
	int idx = 0;
	int graphOrder = 0;
	int dirtMask = 0;
	List<ActorComponent> dependents;

	ActorComponent.withActor(Actor actor)
	{
		this.actor = actor;
	}

	ActorComponent()
	{

	}

	String get name
	{
		return _name;
	}

	void resolveComponentIndices(List<ActorComponent> components)
	{
		ActorNode node = components[_parentIdx] as ActorNode;
		if(node != null)
		{
			if(this is ActorNode)
			{
				node.addChild(this as ActorNode);
			}
			else
			{
				parent = node;
			}
			actor.addDependency(this, node);
		}
	}

	void completeResolve();
	ActorComponent makeInstance(Actor resetActor);
	void onDirty(int dirt);
	void update(int dirt);

	static ActorComponent read(Actor actor, BinaryReader reader, ActorComponent component)
	{
		component.actor = actor;
		component._name = reader.readString();
		component._parentIdx = reader.readUint16();

		return component;
	}

	void copyComponent(ActorComponent component, Actor resetActor)
	{
		_name = component._name;
		actor = resetActor;
		_parentIdx = component._parentIdx;
		idx = component.idx;
	}
}