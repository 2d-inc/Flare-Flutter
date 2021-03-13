import 'actor_artboard.dart';
import 'actor_component.dart';
import 'actor_shadow.dart';

class ActorInnerShadow extends ActorShadow {
  @override
  int get blendModeId => 0;
  @override
  set blendModeId(int value) {}

  @override
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    ActorInnerShadow instanceShape = resetArtboard.actor.makeInnerShadow();
    instanceShape.copyShadow(this, resetArtboard);
    return instanceShape;
  }
}
