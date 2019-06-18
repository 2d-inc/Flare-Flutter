import "dart:collection";
import "package:flutter/foundation.dart";
import "actor_component.dart";

class _DependencyNode {
  int index;
  List<_DependencyNode> dependents;
}

class _DependencyNodeSorter {
  final HashSet<_DependencyNode> _perm = HashSet<_DependencyNode>();
  final HashSet<_DependencyNode> _temp = HashSet<_DependencyNode>();
  List<_DependencyNode> _order;

  List<_DependencyNode> sort(_DependencyNode root) {
    _order = <_DependencyNode>[];
    if (!visit(root)) {
      return null;
    }
    return _order;
  }

  bool visit(_DependencyNode n) {
    if (_perm.contains(n)) {
      return true;
    }
    if (_temp.contains(n)) {
      print("Dependency cycle!");
      return false;
    }

    _temp.add(n);

    List<_DependencyNode> dependents = n.dependents;
    if (dependents != null) {
      for (final _DependencyNode d in dependents) {
        if (!visit(d)) {
          return false;
        }
      }
    }
    _perm.add(n);
    _order.insert(0, n);

    return true;
  }
}

class DependencySorter {
  List<_DependencyNode> _dependencyNodes;
  List<ActorComponent> _components;

  DependencySorter(this._components) {
    int index = 0;

    // We internally story the dependencies as indices in order to allow
    // computing them in a separate isolate.

    // Make a list of the dependency nodes with their respective indices.
    _dependencyNodes = _components.map((component) {
      return _DependencyNode()..index = index++;
    }).toList(growable: false);

    // Resolve dependent components as dependent nodes.
    for (final _DependencyNode node in _dependencyNodes) {
      final component = _components[node.index];
      node.dependents = component.dependents?.map((dependent) {
        return _dependencyNodes[_components.indexOf(dependent)];
      })?.toList(growable: false);
    }
  }

  Future<List<ActorComponent>> sort() async {
    List<_DependencyNode> sorted = await compute(_sort, _dependencyNodes[0]);

    List<ActorComponent> result = List<ActorComponent>(sorted.length);
    for (int i = 0, length = sorted.length; i < length; i++) {
      final _DependencyNode node = sorted[i];
      result[i] = _components[node.index];
    }
    return result;
  }

  List<ActorComponent> sortSync() {
    _DependencyNodeSorter sorter = _DependencyNodeSorter();
    List<_DependencyNode> sorted = sorter.sort(_dependencyNodes[0]);

    List<ActorComponent> result = List<ActorComponent>(sorted.length);
    for (int i = 0, length = sorted.length; i < length; i++) {
      final _DependencyNode node = sorted[i];
      result[i] = _components[node.index];
    }
    return result;
  }
}

Future<List<_DependencyNode>> _sort(_DependencyNode root) async {
  _DependencyNodeSorter sorter = _DependencyNodeSorter();
  return sorter.sort(root);
}
