import 'actor_artboard.dart';
import 'actor_component.dart';
import 'actor_layer_effect.dart';
import 'stream_reader.dart';

class ActorBlur extends ActorLayerEffect {
  late double blurX;
  late double blurY;

  // ignore: prefer_constructors_over_static_methods
  static ActorBlur read(
      ActorArtboard artboard, StreamReader reader, ActorBlur? component) {
    // ignore: parameter_assignments
    component ??= ActorBlur();
    ActorLayerEffect.read(artboard, reader, component);
    component.blurX = reader.readFloat32('blurX');
    component.blurY = reader.readFloat32('blurY');

    return component;
  }

  void copyBlur(ActorBlur from, ActorArtboard resetArtboard) {
    copyLayerEffect(from, resetArtboard);
    blurX = from.blurX;
    blurY = from.blurY;
  }

  @override
  void completeResolve() {
    // intentionally empty, no logic to complete.
  }

  @override
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    ActorBlur instanceNode = ActorBlur();
    instanceNode.copyBlur(this, resetArtboard);
    return instanceNode;
  }

  @override
  void onDirty(int dirt) {
    // intentionally empty
  }

  @override
  void update(int dirt) {
    // intentionally empty
  }
}
