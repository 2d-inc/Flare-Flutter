import 'package:flare_dart/actor_drop_shadow.dart';
import 'package:flare_dart/actor_node.dart';
import 'package:flare_dart/math/aabb.dart';

import 'actor_artboard.dart';
import 'actor_blur.dart';
import 'actor_drawable.dart';
import 'actor_inner_shadow.dart';
import 'actor_mask.dart';

class ActorLayerEffectRendererMask {
  final ActorMask mask;
  final List<ActorDrawable> drawables = [];
  ActorLayerEffectRendererMask(this.mask);
}

class ActorLayerEffectRenderer extends ActorDrawable {
  final List<ActorDrawable> _drawables = <ActorDrawable>[];
  List<ActorDrawable> get drawables => _drawables;
  final List<ActorLayerEffectRendererMask> _renderMasks = [];
  List<ActorLayerEffectRendererMask> get renderMasks => _renderMasks;
  ActorBlur _blur;
  List<ActorDropShadow> _dropShadows;
  List<ActorInnerShadow> _innerShadows;

  ActorBlur get blur => _blur;
  List<ActorDropShadow> get dropShadows => _dropShadows;
  List<ActorInnerShadow> get innerShadows => _innerShadows;

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
  void onParentChanged(ActorNode from, ActorNode to) {
    super.onParentChanged(from, to);
    from?.findLayerEffect();
    to?.findLayerEffect();
    findEffects();
  }

  @override
  int get blendModeId {
    return 0;
  }

  @override
  set blendModeId(int value) {}

  @override
  AABB computeAABB() {
    return artboard.artboardAABB();
  }

  @override
  ActorLayerEffectRenderer makeInstance(ActorArtboard resetArtboard) {
    ActorLayerEffectRenderer instanceNode =
        resetArtboard.actor.makeLayerEffectRenderer();
    instanceNode.copyDrawable(this, resetArtboard);
    return instanceNode;
  }

  void findEffects() {
    var blurs = parent.children.whereType<ActorBlur>();
    _blur = blurs.isNotEmpty ? blurs.first : null;
    _dropShadows =
        parent.children.whereType<ActorDropShadow>().toList(growable: false);
    _innerShadows =
        parent.children.whereType<ActorInnerShadow>().toList(growable: false);
  }

  @override
  void completeResolve() {
    super.completeResolve();

    // When we complete resolve we find all the children and mark their layers.
    // Alternative way to do this is to have each drawable check for parent
    // layers when the parent changes. That would be more effective if nodes
    // were to get moved around at runtime.
    parent?.all((node) {
      if (node is ActorDrawable && node != this) {
        node.layerEffectRenderer = this;
      }
      return true;
    });
    sortDrawables();
    computeMasks();
    findEffects();
  }

  void computeMasks() {
    _renderMasks.clear();
    var maskSearch = parent;
    var masks = <ActorMask>[];

    while (maskSearch != null) {
      masks +=
          maskSearch.children.whereType<ActorMask>().toList(growable: false);
      maskSearch = maskSearch.parent;
    }

    for (final mask in masks) {
      var renderMask = ActorLayerEffectRendererMask(mask);
      mask.source?.all((child) {
        if (child is ActorDrawable) {
          if (child.layerEffectRenderer != null &&
              child.layerEffectRenderer != this) {
            // Layer effect is direct discendant of this layer, so we want to
            // draw it with the other drawables in this layer.
            renderMask.drawables.add(child.layerEffectRenderer);
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
}
