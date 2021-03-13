import 'package:flare_flutter/base/actor_artboard.dart';
import 'package:flare_flutter/base/actor_node.dart';
import 'package:flare_flutter/base/actor_shape.dart';
import 'package:flare_flutter/base/math/aabb.dart';
import 'package:flare_flutter/base/stream_reader.dart';

abstract class ActorDrawable extends ActorNode {
  final List<List<ClipShape>> _clipShapes = [];
  int _drawOrder = 0;

  // Editor set draw index.
  late int drawIndex;
  late bool isHidden;

  /// If this is set the drawable belongs to a layer. We store a reference to
  /// the parent node that contains the layer.
  ActorNode? layerEffectRenderParent;

  // Computed draw index in the draw list.
  int get blendModeId;
  set blendModeId(int value);

  List<List<ClipShape>> get clipShapes => _clipShapes;

  bool get doesDraw {
    return !isHidden && !renderCollapsed;
  }

  int get drawOrder => _drawOrder;

  set drawOrder(int value) {
    if (_drawOrder == value) {
      return;
    }
    _drawOrder = value;
    artboard.markDrawOrderDirty();
  }

  @override
  void completeResolve() {
    _clipShapes.clear();
    List<List<ActorClip>?> clippers = allClips;
    for (final List<ActorClip?>? clips in clippers) {
      List<ClipShape> shapes = <ClipShape>[];
      for (final ActorClip? clip in clips!) {
        clip!.node.all((component) {
          if (component is ActorShape) {
            shapes.add(ClipShape(component, clip.intersect));
          }
          return true;
        });
      }
      if (shapes.isNotEmpty) {
        _clipShapes.add(shapes);
      }
    }
  }

  AABB computeAABB();
  void copyDrawable(ActorDrawable node, ActorArtboard resetArtboard) {
    copyNode(node, resetArtboard);
    drawOrder = node.drawOrder;
    blendModeId = node.blendModeId;
    isHidden = node.isHidden;
  }

  void initializeGraphics() {}

  static ActorDrawable read(
      ActorArtboard artboard, StreamReader reader, ActorDrawable component) {
    ActorNode.read(artboard, reader, component);

    component.isHidden = !reader.readBool('isVisible');
    if (artboard.actor.version < 21) {
      component.blendModeId = 3;
    } else {
      component.blendModeId = reader.readUint8('blendMode');
    }
    component.drawOrder = reader.readUint16('drawOrder');

    return component;
  }
}

enum BlendModes { normal, multiply, screen, additive }

class ClipShape {
  final ActorShape shape;
  final bool intersect;
  ClipShape(this.shape, this.intersect);
}
