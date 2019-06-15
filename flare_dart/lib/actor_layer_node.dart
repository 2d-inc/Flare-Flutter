import 'package:flare_dart/math/aabb.dart';

import 'actor_artboard.dart';
import 'actor_component.dart';
import 'actor_drawable.dart';

class ActorLayerNode extends ActorDrawable {
  final List<ActorDrawable> _drawables = <ActorDrawable>[];
  List<ActorDrawable> get drawables => _drawables;

  bool addDrawable(ActorDrawable drawable) {
    if (_drawables.contains(drawable)) {
      return false;
    }
    _drawables.add(drawable);
    return true;
  }

  bool removeDrawable(ActorDrawable drawable) => _drawables.remove(drawable);

  void sortDrawables() {
    _drawables
        .sort((ActorDrawable a, ActorDrawable b) => a.drawOrder - b.drawOrder);
  }

  @override
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    ActorLayerNode layer = resetArtboard.actor.makeLayerNode();
    layer.copyDrawable(this, resetArtboard);
    return layer;
  }

  @override
  int blendModeId;

  @override
  AABB computeAABB() {
    AABB aabb;
    for (final ActorDrawable drawable in _drawables) {
      AABB bounds = drawable.computeAABB();
      if (bounds == null) {
        continue;
      }
      if (aabb == null) {
        aabb = bounds;
      } else {
        if (bounds[0] < aabb[0]) {
          aabb[0] = bounds[0];
        }
        if (bounds[1] < aabb[1]) {
          aabb[1] = bounds[1];
        }
        if (bounds[2] > aabb[2]) {
          aabb[2] = bounds[2];
        }
        if (bounds[3] > aabb[3]) {
          aabb[3] = bounds[3];
        }
      }
    }
    return aabb;
  }

  @override
  void completeResolve() {
    super.completeResolve();
    sortDrawables();
  }
}
