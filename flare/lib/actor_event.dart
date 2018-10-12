
import "actor_component.dart";
import "actor.dart";
import "stream_reader.dart";

class ActorEvent extends ActorComponent
{
	static ActorComponent read(Actor actor, StreamReader reader, ActorEvent component)
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
