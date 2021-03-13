import 'dart:async';

import 'package:flare_flutter/asset_provider.dart';
import 'package:flare_flutter/cache.dart';

/// A reference counted asset in a cache.
abstract class CacheAsset {
  late Cache _cache;
  int _refCount = 0;
  final List<Completer<CacheAsset>> _callbacks = [];

  bool get isAvailable;

  void completeLoad() {
    for (final Completer<CacheAsset> callback in _callbacks) {
      callback.complete(this);
    }
    _callbacks.clear();
  }

  void deref() {
    _refCount--;
    if (_refCount == 0) {
      _cache.drop(this);
    }
  }

  void load(Cache cache, AssetProvider assetProvider) => _cache = cache;

  Future<CacheAsset> onLoaded() async {
    if (isAvailable) {
      return this;
    }
    Completer<CacheAsset> completer = Completer<CacheAsset>();
    _callbacks.add(completer);
    return completer.future;
  }

  void ref() {
    _refCount++;
    if (_refCount == 1) {
      _cache.hold(this);
    }
  }
}
