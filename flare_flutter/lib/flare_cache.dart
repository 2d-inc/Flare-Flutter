import 'dart:async';
import 'package:flutter/services.dart';

import 'asset_bundle_cache.dart';
import 'flare_cache_asset.dart';

/// Cache that instances flare assets from ".flr" extension.
class FlareCache extends AssetBundleCache<FlareCacheAsset> {
  FlareCache(AssetBundle bundle) : super(bundle);

  static bool doesPrune = true;
  static Duration pruneDelay = Duration(seconds: 2);

  @override
  bool get isPruningEnabled => doesPrune;

  @override
  Duration get pruneAfter => pruneDelay;

  @override
  FlareCacheAsset makeAsset() {
    return FlareCacheAsset();
  }
}

/// A mapping of loaded Flare assets.
final Map<AssetBundle, FlareCache> _cache = {};

/// Get a cached Flare actor, or load it if it's not yet available.
Future<FlareCacheAsset> cachedActor(AssetBundle bundle, String filename) async {
  FlareCache cache = _cache[bundle];
  if (cache == null) {
    _cache[bundle] = cache = FlareCache(bundle);
  }
  return cache.getAsset(filename);
}
