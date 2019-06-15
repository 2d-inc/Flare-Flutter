import 'dart:typed_data';

import 'actor.dart';
import 'embedded_flare_asset.dart';

abstract class ActorLoadingContext {
  Future<Actor> loadEmbedded(EmbeddedFlareAsset asset);
  Future<Uint8List> loadOutOfBandAsset(String filename);
}
