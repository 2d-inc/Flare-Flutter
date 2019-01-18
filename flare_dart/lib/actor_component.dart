import "stream_reader.dart";
import "actor_artboard.dart";
import "actor_node.dart";

abstract class ActorComponent {
  String _name = "Unnamed";
  ActorNode parent;
  ActorArtboard artboard;
  int _parentIdx = 0;
  int idx = 0;
  int graphOrder = 0;
  int dirtMask = 0;
  List<ActorComponent> dependents;

  ActorComponent.withArtboard(ActorArtboard artboard) {
    this.artboard = artboard;
  }

  ActorComponent() {}

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
  void onDirty(int dirt);
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
}
