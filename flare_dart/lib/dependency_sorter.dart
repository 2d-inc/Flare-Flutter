import "dart:collection";

import "package:graphs/graphs.dart";

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

  bool visit(ActorComponent n, {HashSet<ActorComponent> cycleNodes}) {
    cycleNodes ??= HashSet<ActorComponent>();
    if (cycleNodes.contains(n)) {
      // skip any nodes on a known cycle.
      return true;
    }
    if (_perm.contains(n)) {
      return true;
    }
    if (_temp.contains(n)) {
      // cycle detected!
      return false;
    }

    _temp.add(n);

    List<ActorComponent> dependents = n.dependents;
    if (dependents != null) {
      for (final ActorComponent d in dependents) {
        if (!visit(d, cycleNodes: cycleNodes)) {
          return false;
        }
      }
    }
    _perm.add(n);
    _order.insert(0, n);

    return true;
  }
}

/// Sorts dependencies for Actors even when cycles are present
///
/// Any nodes that form part of a cycle can be found in `cycleNodes` after `sort`.
/// NOTE: Nodes isolated by cycles will not be found in `_order` or `cycleNodes`
///   e.g. `A -> B <-> C -> D` isolates D when running a sort based on A
class TarjansDependencySorter extends DependencySorter {
  HashSet<ActorComponent> _cycleNodes;
  HashSet<ActorComponent> get cycleNodes => _cycleNodes;

  TarjansDependencySorter() {
    _perm = HashSet<ActorComponent>();
    _temp = HashSet<ActorComponent>();
    _cycleNodes = HashSet<ActorComponent>();
  }

  @override
  List<ActorComponent> sort(ActorComponent root) {
    _order = <ActorComponent>[];

    if (!visit(root)) {
      // if we detect cycles, go find them all
      _perm.clear();
      _temp.clear();
      _cycleNodes.clear();
      _order.clear();

      var cycles = stronglyConnectedComponents<ActorComponent>(
          [root], (ActorComponent node) => node.dependents);

      cycles.forEach((cycle) {
        // cycles of len 1 are not cycles.
        if (cycle.length > 1) {
          cycle.forEach((cycleMember) {
            _cycleNodes.add(cycleMember);
          });
        }
      });

      // revisit the tree, skipping nodes on any cycle.
      visit(root, cycleNodes: _cycleNodes);
    }

    return _order;
  }
}
