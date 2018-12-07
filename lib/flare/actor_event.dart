import "actor_component.dart";
import "actor_artboard.dart";
import "stream_reader.dart";

class ActorEvent extends ActorComponent {
  static ActorComponent read(
      ActorArtboard artboard, StreamReader reader, ActorEvent component) {
    if (component == null) {
      component = ActorEvent();
    }

    ActorComponent.read(artboard, reader, component);

    return component;
  }

  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    ActorEvent instanceEvent = ActorEvent();
    instanceEvent.copyComponent(this, resetArtboard);
    return instanceEvent;
  }

  void completeResolve() {}
  void onDirty(int dirt) {}
  void update(int dirt) {}
}
