import 'dart:async';

import 'asset_provider.dart';
import 'cache_asset.dart';

typedef CacheAsset AssetFactoryMethod();

/// A base class for loading cached resources
abstract class Cache<T extends CacheAsset> {
  final Map<AssetProvider, T> _assets = {};
  final Set<T> _toPrune = Set<T>();
  Timer _pruneTimer;

  T makeAsset();

  bool get isPruningEnabled => true;
  Duration get pruneAfter;

  void _prune() {
    for (final T asset in _toPrune) {
      _assets.removeWhere((AssetProvider assetProvider, T cached) {
        return cached == asset;
      });
    }
    _toPrune.clear();
    _pruneTimer = null;
  }

  void drop(T asset) {
    _toPrune.add(asset);
    if (_pruneTimer != null) {
      _pruneTimer.cancel();
    }
    if (isPruningEnabled) {
      _pruneTimer = Timer(pruneAfter, _prune);
    }
  }

  void hold(T asset) {
    _toPrune.remove(asset);
  }

  /// Get an asset from the cache or load it.
  Future<T> getAsset(AssetProvider assetProvider) async {
    T asset = _assets[assetProvider];
    if (asset != null) {
      if (asset.isAvailable) {
        return asset;
      } else {
        return await asset.onLoaded() as T;
      }
    }

    asset = makeAsset();
    assert(asset != null);

    _assets[assetProvider] = asset;
    asset.load(this, assetProvider);
    return asset.isAvailable ? asset : await asset.onLoaded() as T;
  }

  /// Get an asset from the cache.
  T getWarmAsset(AssetProvider assetProvider) {
    T asset = _assets[assetProvider];
    return (asset?.isAvailable ?? false) ? asset : null;
  }
}
