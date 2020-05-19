import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

import '../asset_provider.dart';

/// Fetches a Flare from a [Uint8List].
@immutable
class MemoryFlare extends AssetProvider {
  const MemoryFlare({@required this.bytes}) : assert(bytes != null);

  /// The bytes to decode into a Flare.
  final Uint8List bytes;

  @override
  Future<ByteData> load() async {
    final data = ByteData.view(bytes.buffer);
    assert(data != null);
    return data;
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is MemoryFlare && other.bytes == bytes;
  }

  @override
  int get hashCode => bytes.hashCode;

  @override
  String toString() => '$runtimeType(${describeIdentity(bytes)})';
}
