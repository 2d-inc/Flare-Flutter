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
  Future<void> load(Cache cache, AssetProvider assetProvider) async {
    await super.load(cache, assetProvider);

    final data = await assetProvider.load();
    if (data == null) {
      print("Failed to load flare file from $assetProvider.");
      return;
    }

    final actor = useCompute
        ? await compute(FlutterActor.loadFromByteData, data)
        : await FlutterActor.loadFromByteData(data);
    loadedActor(actor, assetProvider);
  }

  @override
  bool get isAvailable => _actor != null;
}
