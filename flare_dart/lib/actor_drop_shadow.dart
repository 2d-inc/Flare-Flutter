import 'actor_artboard.dart';
import 'actor_component.dart';
import 'actor_shadow.dart';

class ActorDropShadow extends ActorShadow {
  @override
  int get blendModeId => 0;
  @override
  set blendModeId(int value) {}

  @override
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    ActorDropShadow instanceShape = resetArtboard.actor.makeDropShadow();
    instanceShape.copyShadow(this, resetArtboard);
    return instanceShape;
  }
}
