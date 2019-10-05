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

  static bool useCompute = true;

  void loadedActor(FlutterActor actor, String filename) {
    actor.loadImages().then((_) {
      if (actor != null) {
        _actor = actor;
        completeLoad();
      } else {
        print("Failed to load flare file from $filename.");
      }
    });
  }

  @override
  void load(Cache cache, String filename) {
    super.load(cache, filename);
    if (cache is AssetBundleCache) {
      cache.bundle.load(filename).then((ByteData data) {
        if (useCompute) {
          compute(FlutterActor.loadFromByteData, data)
              .then((FlutterActor actor) {
            loadedActor(actor, filename);
          });
        } else {
          FlutterActor.loadFromByteData(data).then((FlutterActor actor) {
            loadedActor(actor, filename);
          });
        }
      });
    }
  }

  @override
  bool get isAvailable => _actor != null;
}
