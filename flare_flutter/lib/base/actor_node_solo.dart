import 'dart:math';

import 'package:flare_flutter/base/actor_artboard.dart';
import 'package:flare_flutter/base/actor_component.dart';
import 'package:flare_flutter/base/actor_node.dart';
import 'package:flare_flutter/base/stream_reader.dart';

class ActorNodeSolo extends ActorNode {
  int _activeChildIndex = 0;

  int get activeChildIndex {
    return _activeChildIndex;
  }

  set activeChildIndex(int idx) {
    if (idx != _activeChildIndex) {
      setActiveChildIndex(idx);
    }
  }

  @override
  void completeResolve() {
    super.completeResolve();
    setActiveChildIndex(activeChildIndex);
  }

  void copySolo(ActorNodeSolo node, ActorArtboard resetArtboard) {
    copyNode(node, resetArtboard);
    _activeChildIndex = node._activeChildIndex;
  }

  @override
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    ActorNodeSolo soloInstance = ActorNodeSolo();
    soloInstance.copySolo(this, resetArtboard);
    return soloInstance;
  }

  // ignore: prefer_constructors_over_static_methods
  void setActiveChildIndex(int idx) {
    if (children != null) {
      _activeChildIndex = min(children!.length, max(0, idx));
      for (int i = 0; i < children!.length; i++) {
        var child = children![i];
        bool cv = i != (_activeChildIndex - 1);
        if (child is ActorNode) {
          child.collapsedVisibility = cv; // Setter
        }
      }
    }
  }

  // ignore: prefer_constructors_over_static_methods
  static ActorNodeSolo read(
      ActorArtboard artboard, StreamReader reader, ActorNodeSolo? node) {
    // ignore: parameter_assignments
    node ??= ActorNodeSolo();

    ActorNode.read(artboard, reader, node);
    node._activeChildIndex = reader.readUint32('activeChild');
    return node;
  }
}
