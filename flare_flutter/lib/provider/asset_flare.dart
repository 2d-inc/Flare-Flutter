import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

import '../asset_provider.dart';

/// Fetches a Flare from an [AssetBundle].
@immutable
class AssetFlare extends AssetProvider {
  const AssetFlare({@required this.bundle, @required this.name})
      : assert(bundle != null),
        assert(name != null);

  /// The bundle from which the Flare will be obtained.
  ///
  /// The Flare is obtained by calling [AssetBundle.load] on the given [bundle]
  /// using the key given by [name].
  final AssetBundle bundle;

  /// The key to use to obtain the resource from the [bundle]. This is the
  /// argument passed to [AssetBundle.load].
  final String name;

  @override
  Future<ByteData> load() async {
    final data = await bundle.load(name);
    assert(data != null);
    return data;
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is AssetFlare && other.bundle == bundle && other.name == name;
  }

  @override
  int get hashCode => hashValues(bundle, name);

  @override
  String toString() => '$runtimeType(bundle: $bundle, name: "$name")';
}
