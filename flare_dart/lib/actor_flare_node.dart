import 'package:flare_dart/embedded_flare_asset.dart';
import 'package:flare_dart/math/aabb.dart';
import 'package:flare_dart/stream_reader.dart';

import 'actor_artboard.dart';
import 'actor_component.dart';
import 'actor_drawable.dart';
import 'math/mat2d.dart';

class ActorFlareNode extends ActorDrawable {
  int _embeddedAssetIndex;
  EmbeddedFlareAsset _asset;
  ActorArtboard _instance;
  bool _usingExistingInstance = false;
  bool get usingExistingInstance => _usingExistingInstance;

  ActorArtboard get instance => _instance;

  @override
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    ActorFlareNode node = resetArtboard.actor.makeFlareNode();
    node.copyFlareNode(this, resetArtboard);
    ActorArtboard artboard = _asset?.artboard;
    if (artboard != null) {
      // TODO: removeDirtyListeners

      // If the asset has been set to an instance, make sure to use that
      // and presume the user knows what they are doing.
      // This is really for cases when you want to mount an embedding item
      // to an already loaded item.
      node._usingExistingInstance = artboard.isInstance;
      node._instance = artboard.isInstance ? artboard : artboard.makeInstance();
    }
    return node;
  }

  ActorComponent getEmbeddedComponent(String name) => _instance?.getNode(name);

  void copyFlareNode(ActorFlareNode node, ActorArtboard resetArtboard) {
    copyDrawable(node, resetArtboard);
    _embeddedAssetIndex = node._embeddedAssetIndex;
    _asset = node._asset;
  }

  @override
  int blendModeId;

  @override
  AABB computeAABB() {
    return _instance?.computeAABB();
  }

  @override
  void resolveComponentIndices(List<ActorComponent> components) {
    super.resolveComponentIndices(components);

    List<EmbeddedFlareAsset> assets = artboard.actor.embeddedAssets;
    if (assets != null && _embeddedAssetIndex < assets.length) {
      _asset = assets[_embeddedAssetIndex];
    }
  }

  @override
  void updateWorldTransform() {
    super.updateWorldTransform();
    if (!_usingExistingInstance &&
        _instance != null &&
        !Mat2D.areEqual(_instance.root.worldTransform, worldTransform)) {
      _instance.root.worldTransformOverride = worldTransform;
      _instance.advance(0);
    }
  }

  static ActorFlareNode read(
      ActorArtboard artboard, StreamReader reader, ActorFlareNode node) {
    ActorDrawable.read(artboard, reader, node);
    node._embeddedAssetIndex = reader.readUint16("assetIndex");
    return node;
  }
}
