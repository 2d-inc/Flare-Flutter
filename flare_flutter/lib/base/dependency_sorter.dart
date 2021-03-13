import 'dart:collection';

import 'actor_component.dart';

class DependencySorter {
  final _perm = HashSet<ActorComponent?>();
  final _temp = HashSet<ActorComponent?>();

  List<ActorComponent?>? sort(ActorComponent root) {
    final order = <ActorComponent?>[];
    if (!_visit(root, order)) {
      return null;
    }
    return order;
  }

  bool _visit(ActorComponent? n, List<ActorComponent?> order) {
    if (_perm.contains(n)) {
      return true;
    }
    if (_temp.contains(n)) {
      print('Dependency cycle!');
      return false;
    }

    _temp.add(n);

    List<ActorComponent?>? dependents = n!.dependents;
    if (dependents != null) {
      for (final ActorComponent? d in dependents) {
        if (!_visit(d, order)) {
          return false;
        }
      }
    }
    _perm.add(n);
    order.insert(0, n);
    return true;
  }
}
