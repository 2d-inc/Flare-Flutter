import "actor_artboard.dart";
import "actor_node.dart";
import "stream_reader.dart";

typedef void DirtListenerCallback(ActorComponent component, int dirt);

abstract class ActorComponent {
  String _name = "Unnamed";
  ActorNode parent;
  ActorArtboard artboard;
  int _parentIdx = 0;
  int idx = 0;
  int graphOrder = 0;
  int dirtMask = 0;
  List<ActorComponent> dependents;
  Set<ActorComponent> _extDependents;
  Set<ActorComponent> get extDependents => _extDependents;
  //final Set<DirtListenerCallback> _dirtListeners = <DirtListenerCallback>{};

  ActorComponent();
  ActorComponent.withArtboard(this.artboard);

  String get name {
    return _name;
  }

  void resolveComponentIndices(List<ActorComponent> components) {
    ActorNode node = components[_parentIdx] as ActorNode;
    if (node != null) {
      if (this is ActorNode) {
        node.addChild(this as ActorNode);
      } else {
        parent = node;
      }
      artboard.addDependency(this, node);
    }
  }

  void completeResolve();
  ActorComponent makeInstance(ActorArtboard resetArtboard);

  void onDirty(int dirt) {
    // for (final DirtListenerCallback listener in _dirtListeners) {
    //   listener(this, dirt);
    // }
  }

  void update(int dirt);

  static ActorComponent read(
      ActorArtboard artboard, StreamReader reader, ActorComponent component) {
    component.artboard = artboard;
    component._name = reader.readString("name");
    component._parentIdx = reader.readId("parent");

    return component;
  }

  void copyComponent(ActorComponent component, ActorArtboard resetArtboard) {
    _name = component._name;
    artboard = resetArtboard;
    _parentIdx = component._parentIdx;
    idx = component.idx;
  }

  bool addExternalDirt(int dirt, bool recurse) =>
      artboard?.addDirt(this, dirt, recurse);

  bool addExternalDependency(ActorComponent component) {
    _extDependents ??= <ActorComponent>{};
    _extDependents.add(component);
    return true;
  }

  bool removeExternalDependency(ActorComponent component) =>
      _extDependents?.remove(component) ?? false;

//   bool addDirtyListener(DirtListenerCallback listener) =>
//       _dirtListeners.add(listener);

//   bool removeDirtyListener(DirtListenerCallback listener) =>
//       _dirtListeners.remove(listener);

//   void removeDirtyListeners() => _dirtListeners.clear();
}
