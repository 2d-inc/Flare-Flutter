import 'dart:typed_data';
import 'package:flare_dart/actor.dart';
import 'package:flare_dart/embedded_flare_asset.dart';
import 'package:flutter/foundation.dart';
import 'package:flare_dart/actor_loading_context.dart';

import 'asset_bundle_cache.dart';
import 'cache.dart';
import 'cache_asset.dart';
import 'flare.dart';
import 'flare_cache.dart';

/// A reference counted asset in a cache.
class FlareCacheAsset extends CacheAsset {
  FlutterActor _actor;
  FlutterActor get actor => _actor;

  @override
  void load(Cache cache, String filename) {
    super.load(cache, filename);
    if (cache is AssetBundleCache) {
      cache.bundle.load(filename).then((ByteData data) {
        compute(_startLoad, data).then((FlutterActor actor) {
          var context = _FlareCacheContext(filename, cache);
          actor.loadImages().then((_) {
            if (actor != null) {
              actor.completeLoad(context).then((bool success) {
                _actor = actor;
                completeLoad();
              });
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

Future<FlutterActor> _startLoad(ByteData data) async {
  FlutterActor actor = FlutterActor();
  await actor.startLoad(data);
  return actor;
}

class _FlareCacheContext extends ActorLoadingContext {
  final AssetBundleCache _cache;
  final String _filename;
  _FlareCacheContext(this._filename, this._cache);

  @override
  Future<Actor> loadEmbedded(EmbeddedFlareAsset asset) async {
    int pathIdx = _filename.lastIndexOf('/') + 1;
    String basePath = _filename.substring(0, pathIdx);
	String filename = basePath + asset.name + ".flr";

    FlareCacheAsset cached =
        await cachedActor(_cache.bundle, filename);
    return cached.actor;
  }

  @override
  Future<Uint8List> loadOutOfBandAsset(String assetFilename) async {
    int pathIdx = _filename.lastIndexOf('/') + 1;
    String basePath = _filename.substring(0, pathIdx);
    ByteData data = await _cache.bundle.load(basePath + assetFilename);
    return Uint8List.view(data.buffer);
  }
}
