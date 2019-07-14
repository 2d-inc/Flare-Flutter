import "dart:async";
import "dart:convert";
import "dart:typed_data";

import "actor_artboard.dart";
import "actor_color.dart";
import "actor_ellipse.dart";
import "actor_flare_node.dart";
import "actor_image.dart";
import "actor_layer_node.dart";
import "actor_loading_context.dart";
import "actor_path.dart";
import "actor_polygon.dart";
import "actor_rectangle.dart";
import "actor_shape.dart";
import "actor_star.dart";
import "actor_triangle.dart";
import "block_types.dart";
import "embedded_flare_asset.dart";
import "stream_reader.dart";

abstract class Actor {
  int maxTextureIndex = 0;
  int _version = 0;
  List<EmbeddedFlareAsset> _embeddedAssets;
  List<ActorArtboard> _artboards;
  List<EmbeddedFlareAsset> get embeddedAssets => _embeddedAssets;
  List<String> _outOfBandAssetFilenames;

  Actor();

  ActorArtboard get artboard => _artboards.isNotEmpty ? _artboards.first : null;

  int get version {
    return _version;
  }

  int get texturesUsed {
    return maxTextureIndex + 1;
  }

  void copyActor(Actor actor) {
    maxTextureIndex = actor.maxTextureIndex;
    int artboardCount = actor._artboards.length;
    if (artboardCount > 0) {
      int idx = 0;
      _artboards = List<ActorArtboard>(artboardCount);
      for (final ActorArtboard artboard in actor._artboards) {
        if (artboard == null) {
          _artboards[idx++] = null;
          continue;
        }
        ActorArtboard instanceArtboard = artboard.makeInstanceWithActor(this);
        _artboards[idx++] = instanceArtboard;
      }
    }
  }

  ActorArtboard makeArtboard(bool isInstance) {
    return ActorArtboard(this, isInstance);
  }

  ActorImage makeImageNode() {
    return ActorImage();
  }

  ActorLayerNode makeLayerNode() {
    return ActorLayerNode();
  }

  ActorFlareNode makeFlareNode() {
    return ActorFlareNode();
  }

  ActorPath makePathNode() {
    return ActorPath();
  }

  ActorShape makeShapeNode() {
    return ActorShape();
  }

  ActorRectangle makeRectangle() {
    return ActorRectangle();
  }

  ActorTriangle makeTriangle() {
    return ActorTriangle();
  }

  ActorStar makeStar() {
    return ActorStar();
  }

  ActorPolygon makePolygon() {
    return ActorPolygon();
  }

  ActorEllipse makeEllipse() {
    return ActorEllipse();
  }

  ColorFill makeColorFill();

  ColorStroke makeColorStroke();

  GradientFill makeGradientFill();

  GradientStroke makeGradientStroke();

  RadialGradientFill makeRadialFill();

  RadialGradientStroke makeRadialStroke();

  Future<bool> loadAtlases(List<Uint8List> rawAtlases);

  /// Perform the full load operation. Do not call this from a background/separate isolate.
  Future<bool> load(ByteData data, ActorLoadingContext context) async {
    if (!await startLoad(data)) {
      return false;
    }
    return completeLoad(context);
  }

  /// Start loading, make sure to call [completeLoad] once this is done.
  Future<bool> startLoad(ByteData data) async {
    if (data.lengthInBytes < 5) {
      throw UnsupportedError("Not a valid Flare file.");
    }

    bool success = true;

    int F = data.getUint8(0);
    int L = data.getUint8(1);
    int A = data.getUint8(2);
    int R = data.getUint8(3);
    int E = data.getUint8(4);

    dynamic inputData = data;

    if (F != 70 || L != 76 || A != 65 || R != 82 || E != 69) {
      Uint8List charCodes = data.buffer.asUint8List();
      String stringData = String.fromCharCodes(charCodes);
      dynamic jsonActor = jsonDecode(stringData);
      Map jsonObject = Map<dynamic, dynamic>();
      jsonObject["container"] = jsonActor;
      inputData = jsonObject;
    }

    StreamReader reader = StreamReader(inputData);
    _version = reader.readVersion();

    StreamReader block;
    while ((block = reader.readNextBlock(BlockTypesMap)) != null) {
      switch (block.blockType) {
        case BlockTypes.EmbeddedAssets:
          readEmbeddedAssets(block);
          break;

        case BlockTypes.Artboards:
          readArtboardsBlock(block);
          break;

        case BlockTypes.Atlases:
          List<Uint8List> rawAtlases = await readAtlasesBlock(block);
          if (rawAtlases.isNotEmpty) {
            success = await loadAtlases(rawAtlases);
          }
          break;
      }
    }

    return success;
  }

  /// This completes the previously started load operation. This is broken into
  /// two parts so that the first part can be called by an isolate and the
  /// embedded load can trigger from the main isolate.
  Future<bool> completeLoad(ActorLoadingContext context) async {
    // Load any out of band assets that were read in while starting the
    // read operation.
    if (_outOfBandAssetFilenames != null &&
        _outOfBandAssetFilenames.isNotEmpty) {
      List<Future<Uint8List>> waitingFor = <Future<Uint8List>>[];
      for (final String filename in _outOfBandAssetFilenames) {
        waitingFor.add(context.loadOutOfBandAsset(filename));
      }
      List<Uint8List> rawAtlases = await Future.wait(waitingFor);
      if (rawAtlases.isNotEmpty && !await loadAtlases(rawAtlases)) {
        return false;
      }
    }

    // Load any embedded assets that were read in while starting
    // the read operation.
    if (_embeddedAssets?.isNotEmpty ?? false) {
      if (!await _loadEmbeddedAssets(context)) {
        // TODO: figure out how we want to handle not being able to load embedded assets.
        //return false;
      }
    }
    // Resolve now.
    for (final ActorArtboard artboard in _artboards) {
      artboard.resolveHierarchy();
    }
    for (final ActorArtboard artboard in _artboards) {
      artboard.completeResolveHierarchy();
    }

    // Sort dependencies last.
    await artboard.sortDependencies();

    return true;
  }

  Future<bool> _loadEmbeddedAssets(ActorLoadingContext context) async {
    List<Future<Actor>> waitingFor = <Future<Actor>>[];

    for (final EmbeddedFlareAsset asset in _embeddedAssets) {
      if (asset != null) {
        waitingFor.add(context.loadEmbedded(asset));
      }
    }
    List<Actor> result = await Future.wait(waitingFor);
    int resultIndex = 0;
    bool success = true;
    for (final EmbeddedFlareAsset asset in _embeddedAssets) {
      if (asset != null) {
        Actor actor = result[resultIndex++];
        if (actor != null) {
          asset.artboard = actor.artboard;
        } else {
          success = false;
        }
      }
    }

    return success;
  }

  void readEmbeddedAssets(StreamReader block) {
    int embeddedAssetCount = block.readUint16Length();
    if (embeddedAssetCount == 0) {
      return;
    }
    _embeddedAssets = List<EmbeddedFlareAsset>(embeddedAssetCount);

    for (int assetIndex = 0, end = _embeddedAssets.length;
        assetIndex < end;
        assetIndex++) {
      StreamReader assetBlock = block.readNextBlock(BlockTypesMap);
      if (assetBlock == null) {
        break;
      }
      switch (assetBlock.blockType) {
        case BlockTypes.EmbeddedFlareAsset:
          {
            EmbeddedFlareAsset asset = EmbeddedFlareAsset(
                assetBlock.readString("name"),
                assetBlock.readString("ownerId"),
                assetBlock.readString("fileId"));
            _embeddedAssets[assetIndex] = asset;
            break;
          }
      }
    }
  }

  void readArtboardsBlock(StreamReader block) {
    int artboardCount = block.readUint16Length();
    _artboards = List<ActorArtboard>(artboardCount);

    for (int artboardIndex = 0, end = _artboards.length;
        artboardIndex < end;
        artboardIndex++) {
      StreamReader artboardBlock = block.readNextBlock(BlockTypesMap);
      if (artboardBlock == null) {
        break;
      }
      switch (artboardBlock.blockType) {
        case BlockTypes.ActorArtboard:
          {
            ActorArtboard artboard = makeArtboard(false);
            artboard.read(artboardBlock);
            _artboards[artboardIndex] = artboard;
            break;
          }
      }
    }
  }

  Future<List<Uint8List>> readAtlasesBlock(StreamReader block) {
    // Determine whether or not the atlas is in or out of band.
    bool isOOB = block.readBool("isOOB");
    block.openArray("data");
    int numAtlases = block.readUint16Length();
    Future<List<Uint8List>> result;
    if (isOOB) {
      _outOfBandAssetFilenames = <String>[];
      for (int i = 0; i < numAtlases; i++) {
        _outOfBandAssetFilenames.add(block.readString("data"));
      }
    } else {
      // This is sync.
      List<Uint8List> inBandAssets = List<Uint8List>(numAtlases);
      for (int i = 0; i < numAtlases; i++) {
        inBandAssets[i] = block.readAsset();
      }
      Completer<List<Uint8List>> completer = Completer<List<Uint8List>>();
      completer.complete(inBandAssets);
      result = completer.future;
    }
    block.closeArray();
    return result;
  }
}
