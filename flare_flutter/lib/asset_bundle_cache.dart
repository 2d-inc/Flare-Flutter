import 'package:flutter/services.dart';

import 'cache.dart';
import 'cache_asset.dart';

/// A cache that uses an AssetBundle.
abstract class AssetBundleCache<T extends CacheAsset> extends Cache<T> {
  final AssetBundle bundle;
  AssetBundleCache(this.bundle);
}
