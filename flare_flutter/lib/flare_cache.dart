import 'package:flare_flutter/asset_provider.dart';
import 'package:flare_flutter/cache.dart';
import 'package:flare_flutter/flare_cache_asset.dart';

/// Cache for loaded Flare assets.
final _cache = FlareCache();

/// Get a cached Flare actor, or load it if it's not yet available.
Future<FlareCacheAsset> cachedActor(AssetProvider assetProvider) =>
    _cache.getAsset(assetProvider);

/// Get a warm Flare actor that's already in the cache.
FlareCacheAsset? getWarmActor(AssetProvider assetProvider) =>
    _cache.getWarmAsset(assetProvider);

/// Cache that instances Flare assets from ".flr" extension.
class FlareCache extends Cache<FlareCacheAsset> {
  static bool doesPrune = true;
  static Duration pruneDelay = const Duration(seconds: 2);

  @override
  bool get isPruningEnabled => doesPrune;

  @override
  Duration get pruneAfter => pruneDelay;

  @override
  FlareCacheAsset makeAsset() => FlareCacheAsset();
}
