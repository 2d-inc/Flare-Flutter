import 'package:flare_flutter/base/actor_artboard.dart';
import 'package:flare_flutter/base/actor_blur.dart';
import 'package:flare_flutter/base/actor_component.dart';
import 'package:flare_flutter/base/actor_drawable.dart';
import 'package:flare_flutter/base/actor_drop_shadow.dart';
import 'package:flare_flutter/base/actor_inner_shadow.dart';
import 'package:flare_flutter/base/actor_mask.dart';
import 'package:flare_flutter/base/actor_node.dart';
import 'package:flare_flutter/base/actor_shadow.dart';
import 'package:flare_flutter/base/math/aabb.dart';

void _computeLayerNode(ActorDrawable? drawable) {
  ActorNode? parent = drawable;
  while (parent != null) {
    if (parent.layerEffect != null) {
      drawable!.layerEffectRenderParent = parent;
      return;
    }
    parent = parent.parent;
  }
  drawable!.layerEffectRenderParent = null;
}

class ActorLayerEffectRenderer extends ActorDrawable {
  final List<ActorDrawable> _drawables = <ActorDrawable>[];
  final List<ActorLayerEffectRendererMask> _renderMasks = [];
  ActorBlur? _blur;
  List<ActorDropShadow> _dropShadows = [];
  List<ActorInnerShadow> _innerShadows = [];
  @override
  int get blendModeId {
    return 0;
  }

  @override
  set blendModeId(int value) {}

  ActorBlur? get blur => _blur;
  List<ActorDrawable> get drawables => _drawables;
  List<ActorDropShadow> get dropShadows => _dropShadows;
  List<ActorInnerShadow> get innerShadows => _innerShadows;

  List<ActorLayerEffectRendererMask> get renderMasks => _renderMasks;

  @override
  void completeResolve() {
    super.completeResolve();

    _drawables.clear();

    parent?.all((node) {
      if (node == this) {
        // don't recurse into this renderer
        return false;
      } else if (node is ActorNode &&
          node.layerEffect != null &&
          node.layerEffect != this) {
        _drawables.add(node.layerEffect!);
        // don't recurse further into nodes that are drawing to layers
        return false;
      }
      if (node is ActorDrawable) {
        _drawables.add(node);
      }
      return true;
    });

    _drawables.forEach(_computeLayerNode);

    sortDrawables();
    computeMasks();
    findEffects();
  }

  @override
  AABB computeAABB() {
    return artboard.artboardAABB();
  }

  void computeMasks() {
    _renderMasks.clear();
    var masks =
        parent!.children!.whereType<ActorMask>().toList(growable: false);

    for (final mask in masks) {
      var renderMask = ActorLayerEffectRendererMask(mask);
      mask.source?.all((child) {
        if (child == parent) {
          // recursive mask was selected
          return false;
        }
        if (child is ActorDrawable) {
          if (child == this) {
            return false;
          } else if (child.layerEffect != null) {
            // Layer effect is direct discendant of this layer, so we want to
            // draw it with the other drawables in this layer.
            renderMask.drawables.add(child.layerEffect!);
            // Don't iterate if child has further layer effect
            return false;
          } else {
            renderMask.drawables.add(child);
          }
        }
        return true;
      });

      if (renderMask.drawables.isNotEmpty) {
        _renderMasks.add(renderMask);
      }
    }
  }

  void findEffects() {
    var blurs = parent!.children!
        .where((child) => child is ActorBlur && child is! ActorShadow)
        .toList(growable: false);
    _blur = blurs.isNotEmpty ? blurs.first as ActorBlur : null;
    _dropShadows =
        parent!.children!.whereType<ActorDropShadow>().toList(growable: false);
    _innerShadows =
        parent!.children!.whereType<ActorInnerShadow>().toList(growable: false);
  }

  @override
  ActorLayerEffectRenderer makeInstance(ActorArtboard resetArtboard) {
    ActorLayerEffectRenderer instanceNode =
        resetArtboard.actor.makeLayerEffectRenderer();
    instanceNode.copyDrawable(this, resetArtboard);
    return instanceNode;
  }

  @override
  void onParentChanged(ActorNode? from, ActorNode? to) {
    super.onParentChanged(from, to);
    from?.findLayerEffect();
    to?.findLayerEffect();
    findEffects();
  }

  @override
  void resolveComponentIndices(List<ActorComponent?> components) {
    super.resolveComponentIndices(components);
    parent!.findLayerEffect();
  }

  void sortDrawables() {
    _drawables.sort(
        (ActorDrawable? a, ActorDrawable? b) => a!.drawOrder - b!.drawOrder);
  }
}

class ActorLayerEffectRendererMask {
  final ActorMask mask;
  final List<ActorDrawable> drawables = [];
  ActorLayerEffectRendererMask(this.mask);
}
