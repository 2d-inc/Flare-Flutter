import 'dart:typed_data';

/// Identifies an asset, to obtain asset from an [AssetProvider], call [load].
abstract class AssetProvider {
  const AssetProvider();

  /// Loads the asset.
  Future<ByteData> load();
}
