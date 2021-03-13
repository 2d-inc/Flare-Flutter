import 'dart:async';

import 'package:flare_flutter/asset_provider.dart';
import 'package:flare_flutter/cache_asset.dart';

typedef CacheAsset AssetFactoryMethod();

/// A base class for loading cached resources
abstract class Cache<T extends CacheAsset> {
  final Map<AssetProvider, T> _assets = {};
  final Set<T> _toPrune = <T>{};
  Timer? _pruneTimer;

  bool get isPruningEnabled => true;

  Duration get pruneAfter;
  void drop(T asset) {
    _toPrune.add(asset);
    _pruneTimer?.cancel();
    if (isPruningEnabled) {
      _pruneTimer = Timer(pruneAfter, _prune);
    }
  }

  /// Get an asset from the cache or load it.
  Future<T> getAsset(AssetProvider assetProvider) async {
    T? asset = _assets[assetProvider];
    if (asset != null) {
      if (asset.isAvailable) {
        return asset;
      } else {
        return await asset.onLoaded() as T;
      }
    }

    asset = makeAsset();

    _assets[assetProvider] = asset;
    asset.load(this, assetProvider);
    return asset.isAvailable ? asset : await asset.onLoaded() as T;
  }

  /// Get an asset from the cache.
  T? getWarmAsset(AssetProvider assetProvider) {
    T? asset = _assets[assetProvider];
    return (asset?.isAvailable ?? false) ? asset : null;
  }

  void hold(T asset) {
    _toPrune.remove(asset);
  }

  T makeAsset();

  void _prune() {
    for (final T asset in _toPrune) {
      _assets.removeWhere((AssetProvider assetProvider, T cached) {
        return cached == asset;
      });
    }
    _toPrune.clear();
    _pruneTimer = null;
  }
}
