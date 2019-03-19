import 'package:flare_dart/actor_artboard.dart';
import 'package:flare_dart/actor_component.dart';
import 'package:flare_dart/actor_drawable.dart';
import 'package:flare_dart/math/aabb.dart';
import 'package:flare_dart/math/mat2d.dart';
import 'package:flare_dart/stream_reader.dart';

class ActorCacheNode extends ActorDrawable {
  List<ActorDrawable> _drawables;
  List<ActorDrawable> get drawables => _drawables;

  @override
  int get blendModeId {
    return 0;
  }

  @override
  set blendModeId(int value) {}

  AABB computeOBB() {
    AABB aabb;
    Mat2D inverseWorld = Mat2D.clone(worldTransform);
    Mat2D.invert(inverseWorld, worldTransform);
    Mat2D temp = Mat2D();
    for (final ActorDrawable drawable in _drawables) {
      Mat2D.multiply(temp, inverseWorld, drawable.worldTransform);
      // Get object's OBB into our transform.
      AABB childBounds = drawable.computeOBB().transform(temp);
      if (aabb == null) {
        aabb = childBounds;
      } else {
        AABB.combine(aabb, aabb, childBounds);
      }
    }
    return aabb;
  }

  @override
  AABB computeAABB() {
    AABB aabb;
    for (final ActorDrawable drawable in _drawables) {
      if (aabb == null) {
        aabb = drawable.computeAABB();
      } else {
        AABB.combine(aabb, aabb, drawable.computeAABB());
      }
    }
    return aabb;
  }

  void addDrawable(ActorDrawable drawable) {
    if (_drawables == null) {
      _drawables = [];
    }
    _drawables.add(drawable);
  }

  void updateCache() {}

  static ActorCacheNode read(
      ActorArtboard artboard, StreamReader reader, ActorCacheNode node) {
    ActorDrawable.read(artboard, reader, node);

    return node;
  }

  @override
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    ActorCacheNode instanceNode = ActorCacheNode();
    instanceNode.copyCacheNode(this, resetArtboard);
    return instanceNode;
  }

  void copyCacheNode(ActorCacheNode node, ActorArtboard resetArtboard) {
    copyDrawable(node, resetArtboard);
  }

  void sortDrawOrder() {
    if (_drawables != null) {
      _drawables.sort((a, b) => a.drawOrder.compareTo(b.drawOrder));
      for (int i = 0; i < _drawables.length; i++) {
        _drawables[i].drawIndex = i;
      }
    }
  }
}
