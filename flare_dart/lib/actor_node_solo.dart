import "actor_artboard.dart";
import "actor_component.dart";
import "actor_node.dart";
import "stream_reader.dart";
import "dart:math";

class ActorNodeSolo extends ActorNode {
  int _activeChildIndex = 0;

  set activeChildIndex(int idx) {
    if (idx != this._activeChildIndex) {
      this.setActiveChildIndex(idx);
    }
  }

  int get activeChildIndex {
    return this._activeChildIndex;
  }

  void setActiveChildIndex(int idx) {
    if (this.children != null) {
      this._activeChildIndex = min(this.children.length, max(0, idx));
      for (int i = 0; i < this.children.length; i++) {
        var child = this.children[i];
        bool cv = (i != (this._activeChildIndex - 1));
        child.collapsedVisibility = cv; // Setter
      }
    }
  }

  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    ActorNodeSolo soloInstance = ActorNodeSolo();
    soloInstance.copySolo(this, resetArtboard);
    return soloInstance;
  }

  void copySolo(ActorNodeSolo node, ActorArtboard resetArtboard) {
    copyNode(node, resetArtboard);
    _activeChildIndex = node._activeChildIndex;
  }

  static ActorNodeSolo read(
      ActorArtboard artboard, StreamReader reader, ActorNodeSolo node) {
    if (node == null) {
      node = ActorNodeSolo();
    }

    ActorNode.read(artboard, reader, node);
    node._activeChildIndex = reader.readUint32("activeChild");
    return node;
  }

  void completeResolve() {
    super.completeResolve();
    this.setActiveChildIndex(this.activeChildIndex);
  }
}
