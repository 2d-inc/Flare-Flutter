import 'package:flare_dart/actor_artboard.dart';
import 'package:flare_dart/actor_shape.dart';
import 'package:flare_dart/stream_reader.dart';

import 'actor_component.dart';
import 'actor_flare_node.dart';
import 'actor_layer_node.dart';
import "actor_node.dart";
import "math/aabb.dart";

enum BlendModes { Normal, Multiply, Screen, Additive }

abstract class ActorDrawable extends ActorNode {
  List<List<ActorShape>> _clipShapes;
  List<List<ActorShape>> get clipShapes => _clipShapes;

  /// Editor set draw index.
  int _drawOrder = 0;

  /// Offset which can be used to manually move items in bulk but retain
  /// animation/editor values.
  int _drawOrderOffset = 0;
  int get drawOrderOffset => _drawOrderOffset;
  set drawOrderOffset(int value) {
    if (_drawOrderOffset == value) {
      return;
    }

    int lastOffset = _drawOrderOffset;

    _drawOrderOffset = value;
    // Set draw order to new value.
    setDrawOrder(_drawOrder - lastOffset);
  }

  // Using a function as there was some odd compiler bug where
  // the setter wasn't called.
  void setDrawOrder(int value) {
    int actualValue = value + _drawOrderOffset;
    if (_drawOrder == actualValue) {
      return;
    }
    _drawOrder = actualValue;
    if (_layer != null) {
      _layer.artboard.markDrawOrderDirty();
    } else {
      artboard.markDrawOrderDirty();
    }
  }

  int get drawOrder => _drawOrder;
  set drawOrder(int value) {
    setDrawOrder(value);
  }

  ActorLayerNode _layer;
  ActorLayerNode get layer => _layer;
  set layer(ActorLayerNode value) {
    if (_layer == value) {
      return;
    }
    _layer?.removeDrawable(this);
    _layer = value;
    _layer?.addDrawable(this);
  }

  int _layerId = 0;
  String _layerName;

  // Computed draw index in the draw list.
  int drawIndex;
  bool isHidden;

  bool get doesDraw {
    return !isHidden && !renderCollapsed;
  }

  int get blendModeId;
  set blendModeId(int value);

  static ActorDrawable read(
      ActorArtboard artboard, StreamReader reader, ActorDrawable component) {
    ActorNode.read(artboard, reader, component);

    component.isHidden = !reader.readBool("isVisible");
    component.blendModeId =
        artboard.actor.version < 21 ? 3 : reader.readUint8("blendMode");
    component.drawOrder = reader.readUint16("drawOrder");

    reader.openObject("layer");
    int layerType = reader.readUint8("type");
    switch (layerType) {
      case 1:
        component._layerId = reader.readId("component");
        break;
      case 2:
        component._layerId = reader.readId("component");
        component._layerName = reader.readString("name");
        break;
      default:
        break;
    }
    reader.closeObject();

    return component;
  }

  void copyDrawable(ActorDrawable node, ActorArtboard resetArtboard) {
    copyNode(node, resetArtboard);
    // todo blendmode
    drawOrder = node.drawOrder;
    blendModeId = node.blendModeId;
    isHidden = node.isHidden;
    _layerId = node._layerId;
    _layerName = node._layerName;
  }

  AABB computeAABB();
  void initializeGraphics() {}

  @override
  void resolveComponentIndices(List<ActorComponent> components) {
    super.resolveComponentIndices(components);

    if (_layerId == 0) {
      return;
    }
    ActorComponent layerComponent = components[_layerId];
    if (layerComponent is ActorFlareNode) {
      // layer is in an embedded flare asset
      ActorComponent embeddedComponent =
          layerComponent.getEmbeddedComponent(_layerName);
      if (embeddedComponent is ActorLayerNode) {
        layer = embeddedComponent;
      }
    } else if (layerComponent is ActorLayerNode) {
      layer = layer;
    }
  }

  @override
  void completeResolve() {
    _clipShapes = <List<ActorShape>>[];
    List<List<ActorClip>> clippers = allClips;
    for (final List<ActorClip> clips in clippers) {
      List<ActorShape> shapes = <ActorShape>[];
      for (final ActorClip clip in clips) {
        clip.node.all((ActorNode node) {
          if (node is ActorShape) {
            shapes.add(node);
          }
          return true;
        });
      }
      if (shapes.isNotEmpty) {
        _clipShapes.add(shapes);
      }
    }
  }

  void dislodge() {
    // Should we do this only do this if we're looking at an embedded layer?
    // Might not matter...
    layer?.removeDrawable(this);
  }
}
