import "actor_artboard.dart";
import "actor_component.dart";
import "actor_constraint.dart";
import "actor_flare_node.dart";
import "stream_reader.dart";

abstract class ActorTargetedConstraint extends ActorConstraint {
  int _targetIdx;
  String _targetName;
  ActorComponent _target;

  ActorComponent get target {
    return _target;
  }

  @override
  void resolveComponentIndices(List<ActorComponent> components) {
    super.resolveComponentIndices(components);
    if (_targetIdx != 0) {
      _target = components[_targetIdx];
      if (_target != null) {
        if (_targetName != null && _target is ActorFlareNode) {
          _target =
              (_target as ActorFlareNode).getEmbeddedComponent(_targetName);
          _target?.addExternalDependency(parent);
        } else {
          artboard.addDependency(parent, _target);
        }
      }
    }
  }

  static ActorTargetedConstraint read(ActorArtboard artboard,
      StreamReader reader, ActorTargetedConstraint component) {
    ActorConstraint.read(artboard, reader, component);
    bool isEmbedded = reader.readBool("isEmbedded");
    component._targetIdx = reader.readId("target");
    if (isEmbedded) {
      component._targetName = reader.readString("name");
    }

    return component;
  }

  void copyTargetedConstraint(
      ActorTargetedConstraint node, ActorArtboard resetArtboard) {
    copyConstraint(node, resetArtboard);

    _targetIdx = node._targetIdx;
    _targetName = node._targetName;
  }

  /// Disconnect dependencies if we're targetting an embedded references.
  void dislodge() {
    var components = artboard.components;
    if (_targetIdx != 0) {
      var target = components[_targetIdx];
      if (target != null && _targetName != null && target is ActorFlareNode) {
        _target.removeExternalDependency(parent);
      }
    }
  }
}
