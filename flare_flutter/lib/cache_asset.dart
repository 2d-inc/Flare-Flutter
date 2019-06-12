import 'dart:async';
import 'cache.dart';

/// A reference counted asset in a cache.
abstract class CacheAsset {
  Cache _cache;
  int _refCount = 0;
  bool get isAvailable;

  void ref() {
    _refCount++;
    if (_refCount == 1) {
      _cache.hold(this);
    }
  }

  void deref() {
    _refCount--;
    if (_refCount == 0) {
      _cache.drop(this);
    }
  }

  List<Completer<CacheAsset>> _callbacks;
  Future<CacheAsset> onLoaded() async {
    if (isAvailable) {
      return this;
    }
    _callbacks ??= [];
    Completer<CacheAsset> completer = Completer<CacheAsset>();
    _callbacks.add(completer);
    return completer.future;
  }

  void load(Cache cache, String filename) {
    _cache = cache;
  }

  void completeLoad() {
    if (_callbacks != null) {
      for (final Completer<CacheAsset> callback in _callbacks) {
        callback.complete(this);
      }
      _callbacks = null;
    }
  }
}
