import 'package:flare_flutter/base/actor_artboard.dart';
import 'package:flare_flutter/base/actor_component.dart';
import 'package:flare_flutter/base/stream_reader.dart';

class ActorEvent extends ActorComponent {
  @override
  void completeResolve() {}

  @override
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    ActorEvent instanceEvent = ActorEvent();
    instanceEvent.copyComponent(this, resetArtboard);
    return instanceEvent;
  }

  @override
  void onDirty(int dirt) {}

  @override
  void update(int dirt) {}

  static ActorComponent read(
      ActorArtboard artboard, StreamReader reader, ActorEvent? component) {
    // ignore: parameter_assignments
    component ??= ActorEvent();

    ActorComponent.read(artboard, reader, component);

    return component;
  }
}
