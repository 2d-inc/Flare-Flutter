import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import 'asset_provider.dart';
import 'cache.dart';
import 'cache_asset.dart';
import 'flare.dart';

/// A reference counted asset in a cache.
class FlareCacheAsset extends CacheAsset {
  FlutterActor _actor;
  FlutterActor get actor => _actor;

  static bool useCompute = true;

  void loadedActor(FlutterActor actor, AssetProvider assetProvider) {
    actor.loadImages().then((_) {
      if (actor != null) {
        _actor = actor;
        completeLoad();
      } else {
        print("Failed to load flare file from $assetProvider.");
      }
    });
  }

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

  @override
  bool get isAvailable => _actor != null;
}
