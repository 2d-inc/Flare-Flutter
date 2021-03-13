import 'package:flare_flutter/base/actor_artboard.dart';
import 'package:flare_flutter/base/actor_node.dart';
import 'package:flare_flutter/base/stream_reader.dart';

abstract class ActorComponent {
  String _name = 'Unnamed';
  ActorNode? _parent;
  ActorNode? get parent => _parent;
  set parent(ActorNode? value) {
    if (_parent == value) {
      return;
    }
    ActorNode? from = _parent;
    _parent = value;
    onParentChanged(from, value);
  }

  void onParentChanged(ActorNode? from, ActorNode? to) {}

  late ActorArtboard artboard;
  int _parentIdx = 0;
  int idx = 0;
  int graphOrder = 0;
  int dirtMask = 0;
  List<ActorComponent>? dependents;

  ActorComponent();
  ActorComponent.withArtboard(this.artboard);

  String get name {
    return _name;
  }

  void resolveComponentIndices(List<ActorComponent?> components) {
    ActorNode? node = components[_parentIdx] as ActorNode?;
    if (node != null) {
      node.addChild(this);
      artboard.addDependency(this, node);
    }
  }

  void completeResolve();
  ActorComponent makeInstance(ActorArtboard resetArtboard);
  void onDirty(int dirt);
  void update(int dirt);

  static ActorComponent read(
      ActorArtboard artboard, StreamReader reader, ActorComponent component) {
    component.artboard = artboard;
    component._name = reader.readString('name');
    component._parentIdx = reader.readId('parent');

    return component;
  }

  void copyComponent(ActorComponent component, ActorArtboard resetArtboard) {
    _name = component._name;
    artboard = resetArtboard;
    _parentIdx = component._parentIdx;
    idx = component.idx;
  }
}
