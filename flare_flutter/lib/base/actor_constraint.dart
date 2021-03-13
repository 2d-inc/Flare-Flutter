import 'package:flare_flutter/base/actor_artboard.dart';
import 'package:flare_flutter/base/actor_component.dart';
import 'package:flare_flutter/base/actor_node.dart';
import 'package:flare_flutter/base/stream_reader.dart';

abstract class ActorConstraint extends ActorComponent {
  bool? _isEnabled;
  double? _strength;

  bool get isEnabled {
    return _isEnabled!;
  }

  set isEnabled(bool value) {
    if (value == _isEnabled) {
      return;
    }
    _isEnabled = value;
    markDirty();
  }

  double get strength {
    return _strength!;
  }

  set strength(double value) {
    if (value == _strength) {
      return;
    }
    _strength = value;
    markDirty();
  }

  void constrain(ActorNode node);

  void copyConstraint(ActorConstraint node, ActorArtboard resetArtboard) {
    copyComponent(node, resetArtboard);

    _isEnabled = node._isEnabled;
    _strength = node._strength;
  }

  void markDirty() {
    parent!.markTransformDirty();
  }

  @override
  void onDirty(int dirt) {
    markDirty();
  }

  @override
  void resolveComponentIndices(List<ActorComponent?> components) {
    super.resolveComponentIndices(components);
    if (parent != null) {
      // This works because nodes are exported in hierarchy order,
      // so we are assured constraints get added in order as we resolve indices.
      parent!.addConstraint(this);
    }
  }

  static ActorConstraint read(
      ActorArtboard artboard, StreamReader reader, ActorConstraint component) {
    ActorComponent.read(artboard, reader, component);
    component._strength = reader.readFloat32('strength');
    component._isEnabled = reader.readBool('isEnabled');

    return component;
  }
}
