
import "actor_component.dart";
import "actor.dart";
import "binary_reader.dart";

class ActorEvent extends ActorComponent
{
	static ActorComponent read(Actor actor, BinaryReader reader, ActorEvent component)
	{
		if(component == null)
		{
			component = new ActorEvent();
		}

		ActorComponent.read(actor, reader, component);

		return component;
	}

	ActorComponent makeInstance(Actor resetActor)
	{
		ActorEvent instanceEvent = new ActorEvent();
		instanceEvent.copyComponent(this, resetActor);
		return instanceEvent;
	}

  	void completeResolve() {}
	void onDirty(int dirt) {}
	void update(int dirt) {}
}
