import 'package:flare_flutter/asset_provider.dart';
import 'package:flare_flutter/flare_cache.dart';
import 'package:flare_flutter/flare_cache_asset.dart';
import 'package:flutter/widgets.dart';

/// Create a mobile or tablet layout depending on the screen size.
class FlareCacheBuilder extends StatefulWidget {
  final Widget Function(BuildContext, bool) builder;
  final List<AssetProvider> assetProviders;

  const FlareCacheBuilder(
    this.assetProviders, {
    required this.builder,
    Key? key,
  }) : super(key: key);

  @override
  _FlareCacheBuilderState createState() => _FlareCacheBuilderState();
}

class _FlareCacheBuilderState extends State<FlareCacheBuilder> {
  bool _isWarm = false;
  final Set<FlareCacheAsset> _assets = {};
  AssetBundle get bundle => DefaultAssetBundle.of(context);

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

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, isWarm);
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  void didUpdateWidget(FlareCacheBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
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
  void initState() {
    super.initState();
    _warmup();
  }

  bool _updateWarmth() {
    if (!mounted) {
      return true;
    }
    var assetProviders = widget.assetProviders;

    for (final assetProvider in assetProviders) {
      if (getWarmActor(assetProvider) == null) {
        isWarm = false;
        return false;
      }
    }
    isWarm = true;
    return true;
  }

  void _warmup() {
    if (_updateWarmth()) {
      return;
    }

    for (final assetProvider in widget.assetProviders) {
      if (getWarmActor(assetProvider) == null) {
        cachedActor(assetProvider).then((FlareCacheAsset asset) {
          if (mounted) {
            _assets.add(asset);
            asset.ref();
          }

          _updateWarmth();
        });
      }
    }
  }
}
