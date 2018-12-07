import "actor_component.dart";
import "actor_node.dart";
import "actor_artboard.dart";
import "stream_reader.dart";

abstract class ActorConstraint extends ActorComponent {
  bool _isEnabled;
  double _strength;

  bool get isEnabled {
    return _isEnabled;
  }

  set isEnabled(bool value) {
    if (value == _isEnabled) {
      return;
    }
    _isEnabled = value;
    markDirty();
  }

  void onDirty(int dirt) {
    markDirty();
  }

  double get strength {
    return _strength;
  }

  set strength(double value) {
    if (value == _strength) {
      return;
    }
    _strength = value;
    markDirty();
  }

  void markDirty() {
    parent.markTransformDirty();
  }

  void constrain(ActorNode node);

  void resolveComponentIndices(List<ActorComponent> components) {
    super.resolveComponentIndices(components);
    if (parent != null) {
      // This works because nodes are exported in hierarchy order, so we are assured constraints get added in order as we resolve indices.
      parent.addConstraint(this);
    }
  }

  static ActorConstraint read(
      ActorArtboard artboard, StreamReader reader, ActorConstraint component) {
    ActorComponent.read(artboard, reader, component);
    component._strength = reader.readFloat32("strength");
    component._isEnabled = reader.readBool("isEnabled");

    return component;
  }

  void copyConstraint(ActorConstraint node, ActorArtboard resetArtboard) {
    copyComponent(node, resetArtboard);

    _isEnabled = node._isEnabled;
    _strength = node._strength;
  }
}
