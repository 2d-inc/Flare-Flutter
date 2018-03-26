import "actor_component.dart";
import "actor_constraint.dart";
import "actor.dart";
import "binary_reader.dart";

abstract class ActorTargetedConstraint extends ActorConstraint
{
	int _targetIdx;
	ActorComponent _target;

	ActorComponent get target
	{
		return _target;
	}

	void resolveComponentIndices(List<ActorComponent> components)
	{
		super.resolveComponentIndices(components);
		if(_targetIdx != 0)
		{
			_target = components[_targetIdx];
			if(_target != null)
			{
				actor.addDependency(parent, _target);
			}
		}
	}

	static ActorTargetedConstraint read(Actor actor, BinaryReader reader, ActorTargetedConstraint component)
	{
		ActorConstraint.read(actor, reader, component);
		component._targetIdx = reader.readUint16();

		return component;
	}

	void copyTargetedConstraint(ActorTargetedConstraint node, Actor resetActor)
	{
		copyConstraint(node, resetActor);

		_targetIdx = node._targetIdx;
	}
}