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
