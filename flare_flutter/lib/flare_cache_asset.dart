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
      FlutterActor actor = FlutterActor();
      actor.loadFromBundle(cache.bundle, filename).then((bool success) {
        if (success) {
          // Initialize graphics on base Flare (non-instanced) file.
          // Sets up any shared buffers.
          actor.artboard.initializeGraphics();

          _actor = actor;
          completeLoad();
        } else {
          print("Failed to load flare file from $filename.");
        }
      });
    }
  }

  @override
  bool get isAvailable => _actor != null;
}
