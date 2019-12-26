import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'asset_provider.dart';
import 'flare_cache.dart';
import 'flare_cache_asset.dart';

/// Create a mobile or tablet layout depending on the screen size.
class FlareCacheBuilder extends StatefulWidget {
  final Widget Function(BuildContext, bool) builder;
  final List<AssetProvider> assetProviders;

  const FlareCacheBuilder(this.assetProviders, {Key key, this.builder})
      : super(key: key);

  @override
  _FlareCacheBuilderState createState() => _FlareCacheBuilderState();
}

class _FlareCacheBuilderState extends State<FlareCacheBuilder> {
  bool _isWarm = false;
  bool get isWarm => _isWarm;
  set isWarm(bool value) {
    if (value == _isWarm) {
      return;
    }
    if (mounted) {
      setState(() {
        _isWarm = value;
      });
    }
  }

  final Set<FlareCacheAsset> _assets = {};
  @override
  void initState() {
    super.initState();
    _warmup();
  }

  @override
  void dispose() {
    for (final FlareCacheAsset asset in _assets) {
      asset.deref();
    }
    _assets.clear();
    super.dispose();
  }

  @override
  void didUpdateWidget(FlareCacheBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    _warmup();
  }

  AssetBundle get bundle => DefaultAssetBundle.of(context);

  void _warmup() {
    if (_updateWarmth()) {
      return;
    }

    for (final assetProvider in widget.assetProviders) {
      if (getWarmActor(assetProvider) == null) {
        cachedActor(assetProvider).then((FlareCacheAsset asset) {
          if (mounted && asset != null) {
            _assets.add(asset);
            asset.ref();
          }

          _updateWarmth();
        });
      }
    }
  }

  bool _updateWarmth() {
    if (!mounted) {
      return true;
    }
    var assetProviders = widget.assetProviders;
    if (assetProviders == null) {
      isWarm = true;
      return true;
    }
    for (final assetProvider in assetProviders) {
      if (getWarmActor(assetProvider) == null) {
        isWarm = false;
        return false;
      }
    }
    isWarm = true;
    return true;
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, isWarm);
  }
}
