import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import 'asset_bundle_cache.dart';
import 'cache.dart';
import 'cache_asset.dart';
import 'flare.dart';

/// A reference counted asset in a cache.
class FlareCacheAsset extends CacheAsset {
  FlutterActor _actor;
  FlutterActor get actor => _actor;

  @override
  void load(Cache cache, String filename) {
    super.load(cache, filename);
    if (cache is AssetBundleCache) {
      cache.bundle.load(filename).then((ByteData data) {
        compute(FlutterActor.loadFromByteData, data).then((FlutterActor actor) {
          actor.loadImages().then((_) {
            if (actor != null) {
              _actor = actor;
              completeLoad();
            } else {
              print("Failed to load flare file from $filename.");
            }
          });
        });
      });
    }
  }

  @override
  bool get isAvailable => _actor != null;
}
