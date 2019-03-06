import 'dart:async';
import 'dart:typed_data';

import 'package:flare_dart/actor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class FlareAssetAnimationProvider extends FlareAnimationProvider {
  FlareAssetAnimationProvider(
      {@required this.context,
      @required this.fileName,
      this.assetPath = 'assets/'})
      : assert(context != null),
        assert(fileName != null),
        assertBundle = DefaultAssetBundle.of(context);

  final String fileName;
  final String assetPath;
  final BuildContext context;
  final AssetBundle assertBundle;

  @override
  Future<ByteData> loadAnimation() {
    return assertBundle.load(assetPath + fileName);
  }

  @override
  Future<Uint8List> readOutOfBandAsset(String fileName) async {
    int pathIdx = fileName.lastIndexOf('/') + 1;
    String basePath = fileName.substring(0, pathIdx);
    ByteData data = await assertBundle.load(basePath + fileName);
    return Uint8List.view(data.buffer);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is FlareAssetAnimationProvider &&
              runtimeType == other.runtimeType &&
              fileName == other.fileName &&
              assetPath == other.assetPath;

  @override
  int get hashCode =>
      fileName.hashCode ^
      assetPath.hashCode;



}

class FlareNetworkAnimationProvider extends FlareAnimationProvider {
  FlareNetworkAnimationProvider({@required this.url}) : assert(url != null);

  final String url;

  @override
  Future<ByteData> loadAnimation() async {
    final response = await http.get(url);
    final buffer = response.bodyBytes.buffer;
    return ByteData.view(buffer);
  }

  @override
  Future<Uint8List> readOutOfBandAsset(String fileName) {
    throw UnsupportedError('network provider can\'t load band asset');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is FlareNetworkAnimationProvider &&
              runtimeType == other.runtimeType &&
              url == other.url;

  @override
  int get hashCode => url.hashCode;



}

class FlareCachedNetworkAnimationProvider extends FlareAnimationProvider {
  FlareCachedNetworkAnimationProvider(
      {@required this.url, BaseCacheManager cacheManager})
      : assert(url != null),
        cacheManager =
            cacheManager != null ? cacheManager : DefaultCacheManager();

  final String url;
  final BaseCacheManager cacheManager;

  @override
  Future<ByteData> loadAnimation() async {
    final file = await cacheManager.getSingleFile(url);
    final bytes = Uint8List.fromList(await file.readAsBytes());
    final buffer = bytes.buffer;
    return ByteData.view(buffer);
  }

  @override
  Future<Uint8List> readOutOfBandAsset(String fileName) {
    throw UnsupportedError('cached network provider can\'t load band asset');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is FlareCachedNetworkAnimationProvider &&
              runtimeType == other.runtimeType &&
              url == other.url;

  @override
  int get hashCode => url.hashCode;



}
