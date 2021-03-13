import 'dart:typed_data';

import 'package:flare_flutter/asset_provider.dart';
import 'package:flutter/foundation.dart';

/// Fetches a Flare from a [Uint8List].
@immutable
class MemoryFlare extends AssetProvider {
  /// The bytes to decode into a Flare.
  final Uint8List bytes;

  const MemoryFlare({required this.bytes});

  @override
  int get hashCode => bytes.hashCode;

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is MemoryFlare && other.bytes == bytes;
  }

  @override
  Future<ByteData> load() => Future.value(ByteData.view(bytes.buffer));

  @override
  String toString() => '$runtimeType(${describeIdentity(bytes)})';
}
