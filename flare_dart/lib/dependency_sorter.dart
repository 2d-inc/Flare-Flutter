import "dart:collection";
import "actor_component.dart";

class DependencySorter {
  HashSet<ActorComponent> _perm;
  HashSet<ActorComponent> _temp;
  List<ActorComponent> _order;

  DependencySorter() {
    _perm = HashSet<ActorComponent>();
    _temp = HashSet<ActorComponent>();
  }

  List<ActorComponent> sort(ActorComponent root) {
    _order = <ActorComponent>[];
    if (!visit(root)) {
      return null;
    }
    return _order;
  }

  bool visit(ActorComponent n) {
    if (_perm.contains(n)) {
      return true;
    }
    if (_temp.contains(n)) {
      print("Dependency cycle!");
      return false;
    }

    _temp.add(n);

    List<ActorComponent> dependents = n.dependents;
    if (dependents != null) {
      for (final ActorComponent d in dependents) {
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

class CycleDependencySorter extends DependencySorter {
  HashSet<ActorComponent> _cycleNodes;
  CycleDependencySorter() {
    _perm = HashSet<ActorComponent>();
    _temp = HashSet<ActorComponent>();
    _cycleNodes = HashSet<ActorComponent>();
  }

  HashSet<ActorComponent> get cycleNodes => _cycleNodes;

  @override
  List<ActorComponent> sort(ActorComponent root) {
    _order = <ActorComponent>[];
    visit(root);
    return _order;
  }

  @override
  bool visit(ActorComponent n) {
    // Follow the nodes along their dependencies.
    // track visited nodes,
    // When a cycle is detected,
    //   scrap all visited nodes tracked until the start of the cycle
    //   track these nodes as 'cycleNodes'

    if (_perm.contains(n)) {
      // node's dependencies have already been evaluated.
    } else if (_temp.contains(n)) {
      if (_cycleNodes.contains(n)) {
        // we're onto a cycle that has already been removed.
        return false;
      }
      // node is being evaluated, but not complete yet, CYCLE!
      ActorComponent lastComponent;
      while (lastComponent != n) {
        lastComponent = _order.removeLast();
        _cycleNodes.add(lastComponent);
      }
      return false;
    } else {
      _order.add(n);
      _temp.add(n);
      if (n.dependents != null) {
        for (final ActorComponent dependant in n.dependents) {
          var cycleFound = !visit(dependant);
          if (cycleFound && _cycleNodes.contains(n)) {
            // node is part of a cycle, we're done here.
            return false;
          }
        }
      }
      _perm.add(n);
    }
    return true;
  }
}
