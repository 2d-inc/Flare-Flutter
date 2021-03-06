import "dart:math";
import "dart:typed_data";

import 'package:flare_dart/actor_layer_effect_renderer.dart';

import "actor.dart";
import 'actor_blur.dart';
import "actor_bone.dart";
import "actor_color.dart";
import "actor_component.dart";
import "actor_distance_constraint.dart";
import "actor_drawable.dart";
import "actor_ellipse.dart";
import "actor_event.dart";
import "actor_flags.dart";
import "actor_ik_constraint.dart";
import "actor_image.dart";
import "actor_jelly_bone.dart";
import 'actor_mask.dart';
import "actor_node.dart";
import "actor_node_solo.dart";
import "actor_path.dart";
import "actor_polygon.dart";
import "actor_rectangle.dart";
import "actor_root_bone.dart";
import "actor_rotation_constraint.dart";
import "actor_scale_constraint.dart";
import 'actor_shadow.dart';
import "actor_shape.dart";
import "actor_skin.dart";
import "actor_star.dart";
import "actor_transform_constraint.dart";
import "actor_translation_constraint.dart";
import "actor_triangle.dart";
import "animation/actor_animation.dart";
import "block_types.dart";
import "dependency_sorter.dart";
import "jelly_component.dart";
import "math/aabb.dart";
import "math/vec2d.dart";
import "stream_reader.dart";

class ActorArtboard {
  int _flags = ActorFlags.isDrawOrderDirty;
  int _drawableNodeCount = 0;
  int _nodeCount = 0;
  int _dirtDepth = 0;
  ActorNode? _root;
  List<ActorComponent?>? _components;
  List<ActorNode?>? _nodes;
  final List<ActorDrawable> _drawableNodes = [];
  final List<ActorLayerEffectRenderer> _effectRenderers = [];
  List<ActorAnimation?>? _animations;
  List<ActorComponent?>? _dependencyOrder;
  Actor? _actor;
  String? _name;
  final Vec2D _translation = Vec2D();
  double _width = 0.0;
  double _height = 0.0;
  final Vec2D _origin = Vec2D();
  bool _clipContents = true;
  final Float32List _color = Float32List(4);
  double _modulateOpacity = 1.0;
  Float32List? _overrideColor;

  String? get name => _name;
  double get width => _width;
  double get height => _height;
  Vec2D get origin => _origin;
  Vec2D get translation => _translation;
  bool get clipContents => _clipContents;
  double get modulateOpacity => _modulateOpacity;
  Float32List? get overrideColor => _overrideColor;

  set overrideColor(Float32List? value) {
    _overrideColor = value;
    for (final ActorDrawable drawable in _drawableNodes) {
      addDirt(drawable, DirtyFlags.paintDirty, true);
    }
  }

  set modulateOpacity(double value) {
    _modulateOpacity = value;
    for (final ActorDrawable drawable in _drawableNodes) {
      addDirt(drawable, DirtyFlags.paintDirty, true);
    }
  }

  ActorArtboard(Actor actor) {
    _actor = actor;
    _root = ActorNode.withArtboard(this);
  }

  Actor? get actor => _actor;
  List<ActorComponent?>? get components => _components;
  List<ActorNode?>? get nodes => _nodes;
  List<ActorAnimation?>? get animations => _animations;
  List<ActorDrawable> get drawableNodes => _drawableNodes;
  ActorComponent? operator [](int index) {
    return _components![index];
  }

  int get componentCount => _components!.length;
  int get nodeCount => _nodeCount;
  int get drawNodeCount => _drawableNodeCount;
  ActorNode? get root => _root;

  bool addDependency(ActorComponent? a, ActorComponent b) {
    List<ActorComponent?>? dependents = b.dependents;
    if (dependents == null) {
      b.dependents = dependents = <ActorComponent?>[];
    }
    if (dependents.contains(a)) {
      return false;
    }
    dependents.add(a);
    return true;
  }

  void sortDependencies() {
    DependencySorter sorter = DependencySorter();
    _dependencyOrder = sorter.sort(_root);
    int graphOrder = 0;
    for (final ActorComponent? component in _dependencyOrder!) {
      component!.graphOrder = graphOrder++;
      component.dirtMask = 255;
    }
    _flags |= ActorFlags.isDirty;
  }

  bool addDirt(ActorComponent component, int value, bool recurse) {
    if ((component.dirtMask & value) == value) {
      // Already marked.
      return false;
    }

    // Make sure dirt is set before calling anything that can set more dirt.
    int dirt = component.dirtMask | value;
    component.dirtMask = dirt;

    _flags |= ActorFlags.isDirty;

    component.onDirty(dirt);

    /// If the order of this component is less than the current dirt depth,
    /// update the dirt depth so that the update loop can break out early
    /// and re-run (something up the tree is dirty).
    if (component.graphOrder < _dirtDepth) {
      _dirtDepth = component.graphOrder;
    }
    if (!recurse) {
      return true;
    }
    List<ActorComponent?>? dependents = component.dependents;
    if (dependents != null) {
      for (final ActorComponent? d in dependents) {
        addDirt(d!, value, recurse);
      }
    }

    return true;
  }

  ActorAnimation? getAnimation(String name) {
    for (final ActorAnimation? a in _animations!) {
      if (a!.name == name) {
        return a;
      }
    }
    return null;
  }

  ActorNode? getNode(String name) {
    for (final ActorNode? node in _nodes!) {
      if (node != null && node.name == name) {
        return node;
      }
    }
    return null;
  }

  void markDrawOrderDirty() {
    _flags |= ActorFlags.isDrawOrderDirty;
  }

  ActorArtboard makeInstance() {
    ActorArtboard artboardInstance = _actor!.makeArtboard();
    artboardInstance.copyArtboard(this);
    return artboardInstance;
  }

  ActorArtboard makeInstanceWithActor(Actor actor) {
    ActorArtboard artboardInstance = actor.makeArtboard();
    artboardInstance.copyArtboard(this);
    return artboardInstance;
  }

  void copyArtboard(ActorArtboard artboard) {
    _name = artboard._name;
    Vec2D.copy(_translation, artboard._translation);
    _width = artboard._width;
    _height = artboard._height;
    Vec2D.copy(_origin, artboard._origin);
    _clipContents = artboard._clipContents;

    _color[0] = artboard._color[0];
    _color[1] = artboard._color[1];
    _color[2] = artboard._color[2];
    _color[3] = artboard._color[3];

    //_actor = artboard._actor;
    _animations = artboard._animations;
    _drawableNodeCount = artboard._drawableNodeCount;
    _nodeCount = artboard._nodeCount;

    if (artboard.componentCount != 0) {
      _components = List<ActorComponent?>.filled(artboard.componentCount, null,
          growable: false);
    }
    if (_nodeCount != 0) // This will always be at least 1.
    {
      _nodes = List<ActorNode?>.filled(_nodeCount, null, growable: false);
    }

    if (artboard.componentCount != 0) {
      int idx = 0;

      for (final ActorComponent? component in artboard.components!) {
        if (component == null) {
          _components![idx++] = null;
          continue;
        }
        ActorComponent instanceComponent = component.makeInstance(this);
        _components![idx++] = instanceComponent;
      }
    }
    // Copy dependency order.
    _dependencyOrder = List<ActorComponent?>.filled(
        artboard._dependencyOrder!.length, null,
        growable: false);
    for (final ActorComponent? component in artboard._dependencyOrder!) {
      final ActorComponent localComponent = _components![component!.idx]!;
      _dependencyOrder![component.graphOrder] = localComponent;
      localComponent.dirtMask = 255;
    }

    _flags |= ActorFlags.isDirty;
    _root = _components![0] as ActorNode?;
    resolveHierarchy();
    completeResolveHierarchy();
  }

  void resolveHierarchy() {
    // Resolve nodes.
    int anIdx = 0;

    _drawableNodes.clear();
    int componentCount = this.componentCount;
    for (int i = 1; i < componentCount; i++) {
      ActorComponent? c = _components![i];

      /// Nodes can be null if we read from a file version that contained
      /// nodes that we don't interpret in this runtime.
      if (c != null) {
        c.resolveComponentIndices(_components!);
      }

      if (c is ActorNode) {
        ActorNode an = c;
        if (an != null) {
          _nodes![anIdx++] = an;
        }
      }
    }
  }

  void completeResolveHierarchy() {
    int componentCount = this.componentCount;

    // Complete resolve.
    for (int i = 1; i < componentCount; i++) {
      ActorComponent? c = components![i];
      if (c != null) {
        c.completeResolve();
      }
    }

    // Build lists. Important to do this after all components have resolved as
    // layers won't be known before this.
    for (int i = 1; i < componentCount; i++) {
      ActorComponent? c = components![i];
      if (c is ActorDrawable && c.layerEffectRenderParent == null) {
        _drawableNodes.add(c);
      }
      if (c is ActorLayerEffectRenderer && c.layerEffectRenderParent == null) {
        _effectRenderers.add(c);
      }
    }

    sortDrawOrder();
  }

  void sortDrawOrder() {
    _drawableNodes.sort((a, b) => a.drawOrder!.compareTo(b.drawOrder!));
    for (int i = 0; i < _drawableNodes.length; i++) {
      _drawableNodes[i].drawIndex = i;
    }
    for (final ActorLayerEffectRenderer layer in _effectRenderers) {
      layer.sortDrawables();
    }
  }

  void advance(double seconds) {
    if ((_flags & ActorFlags.isDirty) != 0) {
      const int maxSteps = 100;
      int step = 0;
      int count = _dependencyOrder!.length;
      while ((_flags & ActorFlags.isDirty) != 0 && step < maxSteps) {
        _flags &= ~ActorFlags.isDirty;
        // Track dirt depth here so that if something else marks
        // dirty, we restart.
        for (int i = 0; i < count; i++) {
          ActorComponent component = _dependencyOrder![i]!;
          _dirtDepth = i;
          int d = component.dirtMask;
          if (d == 0) {
            continue;
          }
          component.dirtMask = 0;
          component.update(d);
          if (_dirtDepth < i) {
            break;
          }
        }
        step++;
      }
    }

    if ((_flags & ActorFlags.isDrawOrderDirty) != 0) {
      _flags &= ~ActorFlags.isDrawOrderDirty;
      sortDrawOrder();
    }
  }

  void read(StreamReader reader) {
    _name = reader.readString("name");
    Vec2D.copyFromList(_translation, reader.readFloat32Array(2, "translation"));
    _width = reader.readFloat32("width");
    _height = reader.readFloat32("height");
    Vec2D.copyFromList(_origin, reader.readFloat32Array(2, "origin"));
    _clipContents = reader.readBool("clipContents");

    Float32List color = reader.readFloat32Array(4, "color");
    _color[0] = color[0];
    _color[1] = color[1];
    _color[2] = color[2];
    _color[3] = color[3];

    StreamReader? block;
    while ((block = reader.readNextBlock(blockTypesMap)) != null) {
      switch (block!.blockType) {
        case BlockTypes.components:
          readComponentsBlock(block);
          break;
        case BlockTypes.animations:
          readAnimationsBlock(block);
          break;
      }
    }
  }

  void readComponentsBlock(StreamReader block) {
    int componentCount = block.readUint16Length();
    _components =
        List<ActorComponent?>.filled(componentCount + 1, null, growable: false);
    _components![0] = _root;

    // Guaranteed from the exporter to be in index order.
    _nodeCount = 1;
    for (int componentIndex = 1, end = componentCount + 1;
        componentIndex < end;
        componentIndex++) {
      StreamReader? nodeBlock = block.readNextBlock(blockTypesMap);
      if (nodeBlock == null) {
        break;
      }
      ActorComponent? component;
      switch (nodeBlock.blockType) {
        case BlockTypes.actorNode:
          component = ActorNode.read(this, nodeBlock, null);
          break;

        case BlockTypes.actorBone:
          component = ActorBone.read(this, nodeBlock, null);
          break;

        case BlockTypes.actorRootBone:
          component = ActorRootBone.read(this, nodeBlock, null);
          break;

        // TODO: fix sequences for flare.
        // case BlockTypes.ActorImageSequence:
        //   component =
        //       ActorImage.readSequence(this, nodeBlock, actor.makeImageNode());
        //   ActorImage ai = component as ActorImage;
        //   actor.maxTextureIndex = ai
        //       .sequenceFrames.last.atlasIndex; // Last atlasIndex is the biggest
        //   break;

        case BlockTypes.actorImage:
          component = ActorImage.read(this, nodeBlock, actor!.makeImageNode());
          if ((component as ActorImage).textureIndex > actor!.maxTextureIndex) {
            actor!.maxTextureIndex = component.textureIndex;
          }
          break;

        case BlockTypes.actorIKTarget:
          //component = ActorIKTarget.Read(this, nodeBlock);
          break;

        case BlockTypes.actorEvent:
          component = ActorEvent.read(this, nodeBlock, null);
          break;

        case BlockTypes.customIntProperty:
          //component = CustomIntProperty.Read(this, nodeBlock);
          break;

        case BlockTypes.customFloatProperty:
          //component = CustomFloatProperty.Read(this, nodeBlock);
          break;

        case BlockTypes.customStringProperty:
          //component = CustomStringProperty.Read(this, nodeBlock);
          break;

        case BlockTypes.customBooleanProperty:
          //component = CustomBooleanProperty.Read(this, nodeBlock);
          break;

        case BlockTypes.actorColliderRectangle:
          //component = ActorColliderRectangle.Read(this, nodeBlock);
          break;

        case BlockTypes.actorColliderTriangle:
          //component = ActorColliderTriangle.Read(this, nodeBlock);
          break;

        case BlockTypes.actorColliderCircle:
          //component = ActorColliderCircle.Read(this, nodeBlock);
          break;

        case BlockTypes.actorColliderPolygon:
          //component = ActorColliderPolygon.Read(this, nodeBlock);
          break;

        case BlockTypes.actorColliderLine:
          //component = ActorColliderLine.Read(this, nodeBlock);
          break;

        case BlockTypes.actorNodeSolo:
          component = ActorNodeSolo.read(this, nodeBlock, null);
          break;

        case BlockTypes.actorJellyBone:
          component = ActorJellyBone.read(this, nodeBlock, null);
          break;

        case BlockTypes.jellyComponent:
          component = JellyComponent.read(this, nodeBlock, null);
          break;

        case BlockTypes.actorIKConstraint:
          component = ActorIKConstraint.read(this, nodeBlock, null);
          break;

        case BlockTypes.actorDistanceConstraint:
          component = ActorDistanceConstraint.read(this, nodeBlock, null);
          break;

        case BlockTypes.actorTranslationConstraint:
          component = ActorTranslationConstraint.read(this, nodeBlock, null);
          break;

        case BlockTypes.actorScaleConstraint:
          component = ActorScaleConstraint.read(this, nodeBlock, null);
          break;

        case BlockTypes.actorRotationConstraint:
          component = ActorRotationConstraint.read(this, nodeBlock, null);
          break;

        case BlockTypes.actorTransformConstraint:
          component = ActorTransformConstraint.read(this, nodeBlock, null);
          break;

        case BlockTypes.actorShape:
          component =
              ActorShape.read(this, nodeBlock, actor!.makeShapeNode(null));
          break;

        case BlockTypes.actorPath:
          component = ActorPath.read(this, nodeBlock, actor!.makePathNode());
          break;

        case BlockTypes.colorFill:
          component = ColorFill.read(this, nodeBlock, actor!.makeColorFill());
          break;

        case BlockTypes.colorStroke:
          component =
              ColorStroke.read(this, nodeBlock, actor!.makeColorStroke());
          break;

        case BlockTypes.gradientFill:
          component =
              GradientFill.read(this, nodeBlock, actor!.makeGradientFill());
          break;

        case BlockTypes.gradientStroke:
          component =
              GradientStroke.read(this, nodeBlock, actor!.makeGradientStroke());
          break;

        case BlockTypes.radialGradientFill:
          component =
              RadialGradientFill.read(this, nodeBlock, actor!.makeRadialFill());
          break;

        case BlockTypes.radialGradientStroke:
          component = RadialGradientStroke.read(
              this, nodeBlock, actor!.makeRadialStroke());
          break;

        case BlockTypes.actorEllipse:
          component = ActorEllipse.read(this, nodeBlock, actor!.makeEllipse());
          break;

        case BlockTypes.actorRectangle:
          component =
              ActorRectangle.read(this, nodeBlock, actor!.makeRectangle());
          break;

        case BlockTypes.actorTriangle:
          component =
              ActorTriangle.read(this, nodeBlock, actor!.makeTriangle());
          break;

        case BlockTypes.actorStar:
          component = ActorStar.read(this, nodeBlock, actor!.makeStar());
          break;

        case BlockTypes.actorPolygon:
          component = ActorPolygon.read(this, nodeBlock, actor!.makePolygon());
          break;

        case BlockTypes.actorSkin:
          component = ActorComponent.read(this, nodeBlock, ActorSkin());
          break;

        case BlockTypes.actorLayerEffectRenderer:
          component = ActorDrawable.read(
              this, nodeBlock, actor!.makeLayerEffectRenderer());
          break;

        case BlockTypes.actorMask:
          component = ActorMask.read(this, nodeBlock, ActorMask());
          break;

        case BlockTypes.actorBlur:
          component = ActorBlur.read(this, nodeBlock, null);
          break;

        case BlockTypes.actorDropShadow:
          component =
              ActorShadow.read(this, nodeBlock, actor!.makeDropShadow());
          break;

        case BlockTypes.actorInnerShadow:
          component =
              ActorShadow.read(this, nodeBlock, actor!.makeInnerShadow());
          break;
      }
      if (component is ActorDrawable) {
        _drawableNodeCount++;
      }

      if (component is ActorNode) {
        _nodeCount++;
      }
      _components![componentIndex] = component;
      if (component != null) {
        component.idx = componentIndex;
      }
    }

    _nodes = List<ActorNode?>.filled(_nodeCount, null, growable: false);
    _nodes![0] = _root;
  }

  void initializeGraphics() {
    // Iterate components as some drawables may end up in other layers.
    for (final ActorComponent? component in _components!) {
      if (component is ActorDrawable) {
        component.initializeGraphics();
      }
    }
  }

  void readAnimationsBlock(StreamReader block) {
    // Read animations.
    int animationCount = block.readUint16Length();
    _animations =
        List<ActorAnimation?>.filled(animationCount, null, growable: false);
    StreamReader? animationBlock;
    int animationIndex = 0;

    while ((animationBlock = block.readNextBlock(blockTypesMap)) != null) {
      switch (animationBlock!.blockType) {
        case BlockTypes.animation:
          ActorAnimation anim =
              ActorAnimation.read(animationBlock, _components);
          _animations![animationIndex++] = anim;
          break;
      }
    }
  }

  AABB artboardAABB() {
    double minX = -1 * _origin[0] * width;
    double minY = -1 * _origin[1] * height;
    return AABB.fromValues(minX, minY, minX + _width, minY + height);
  }

  AABB? computeAABB() {
    AABB? aabb;
    for (final ActorDrawable drawable in _drawableNodes) {
      // This is the axis aligned bounding box in the space
      // of the parent (this case our shape).
      AABB pathAABB = drawable.computeAABB();

      if (aabb == null) {
        aabb = pathAABB;
      } else {
        // Combine.
        aabb[0] = min(aabb[0], pathAABB[0]);
        aabb[1] = min(aabb[1], pathAABB[1]);

        aabb[2] = max(aabb[2], pathAABB[2]);
        aabb[3] = max(aabb[3], pathAABB[3]);
      }
    }

    return aabb;
  }
}
