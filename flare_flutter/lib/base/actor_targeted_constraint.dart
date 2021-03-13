import 'package:flare_flutter/base/actor_artboard.dart';
import 'package:flare_flutter/base/actor_component.dart';
import 'package:flare_flutter/base/actor_constraint.dart';
import 'package:flare_flutter/base/stream_reader.dart';

abstract class ActorTargetedConstraint extends ActorConstraint {
  late int _targetIdx;
  ActorComponent? _target;

  ActorComponent? get target {
    return _target;
  }

  @override
  void resolveComponentIndices(List<ActorComponent?> components) {
    super.resolveComponentIndices(components);
    if (_targetIdx != 0) {
      _target = components[_targetIdx];
      if (_target != null) {
        artboard.addDependency(parent!, _target!);
      }
    }
  }

  static ActorTargetedConstraint read(ActorArtboard artboard,
      StreamReader reader, ActorTargetedConstraint component) {
    ActorConstraint.read(artboard, reader, component);
    component._targetIdx = reader.readId('target');

    return component;
  }

  void copyTargetedConstraint(
      ActorTargetedConstraint node, ActorArtboard resetArtboard) {
    copyConstraint(node, resetArtboard);

    _targetIdx = node._targetIdx;
  }
}
