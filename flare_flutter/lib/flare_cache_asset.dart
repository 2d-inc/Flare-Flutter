import 'package:flare_flutter/asset_provider.dart';
import 'package:flare_flutter/cache.dart';
import 'package:flare_flutter/cache_asset.dart';
import 'package:flare_flutter/flare.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// A reference counted asset in a cache.
class FlareCacheAsset extends CacheAsset {
  static bool useCompute = true;
  FlutterActor? _actor;

  FlutterActor? get actor => _actor;

  @override
  bool get isAvailable => _actor != null;

  @override
  void load(Cache cache, AssetProvider assetProvider) {
    super.load(cache, assetProvider);
    assetProvider.load().then((ByteData data) {
      if (useCompute) {
        compute(FlutterActor.loadFromByteData, data)
            .then((FlutterActor actor) => loadedActor(actor, assetProvider));
      } else {
        FlutterActor.loadFromByteData(data)
            .then((FlutterActor actor) => loadedActor(actor, assetProvider));
      }
    });
  }

  void loadedActor(FlutterActor actor, AssetProvider assetProvider) {
    actor.loadImages().then((_) {
      _actor = actor;
      completeLoad();
    });
  }
}
