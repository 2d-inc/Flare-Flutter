import 'dart:collection';

import 'actor_artboard.dart';
import 'actor_component.dart';
import 'actor_layer_effect.dart';
import 'actor_node.dart';
import 'stream_reader.dart';

enum MaskType { alpha, invertedAlpha, luminance, invertedLuminance }

HashMap<int, MaskType> maskTypeLookup = HashMap<int, MaskType>.fromIterables([
  0,
  1,
  2,
  3
], [
  MaskType.alpha,
  MaskType.invertedAlpha,
  MaskType.luminance,
  MaskType.invertedLuminance
]);

class ActorMask extends ActorLayerEffect {
  late ActorNode _source;
  late int _sourceIdx;
  late MaskType _maskType;
  ActorNode? get source => _source;
  MaskType get maskType => _maskType;

  static ActorMask read(
      ActorArtboard artboard, StreamReader reader, ActorMask component) {
    ActorLayerEffect.read(artboard, reader, component);
    component._sourceIdx = reader.readId('source');
    component._maskType =
        maskTypeLookup[reader.readUint8('maskType')] ?? MaskType.alpha;

    return component;
  }

  void copyMask(ActorMask from, ActorArtboard resetArtboard) {
    copyLayerEffect(from, resetArtboard);
    _sourceIdx = from._sourceIdx;
    _maskType = from._maskType;
  }

  @override
  void resolveComponentIndices(List<ActorComponent?> components) {
    super.resolveComponentIndices(components);

    _source = components[_sourceIdx]! as ActorNode;
  }

  @override
  void completeResolve() {
    // intentionally empty, no logic to complete.
  }

  @override
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    ActorMask instanceNode = ActorMask();
    instanceNode.copyMask(this, resetArtboard);
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
