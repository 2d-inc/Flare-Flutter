import 'dart:async';
import "dart:typed_data";
import "dart:convert";
import "actor_image.dart";
import "actor_shape.dart";
import "actor_ellipse.dart";
import "actor_polygon.dart";
import "actor_rectangle.dart";
import "actor_star.dart";
import "actor_triangle.dart";
import "actor_path.dart";
import "actor_color.dart";
import "stream_reader.dart";
import "block_types.dart";
import "actor_artboard.dart";

abstract class FlareAnimationProvider {
  Future<ByteData> loadAnimation();

  Future<Uint8List> readOutOfBandAsset(String fileName);
}

abstract class Actor {
  int maxTextureIndex = 0;
  int _version = 0;
  int _artboardCount = 0;
  List<ActorArtboard> _artboards;

  Actor();

  ActorArtboard get artboard => _artboards.length > 0 ? _artboards.first : null;

  int get version {
    return _version;
  }

  int get texturesUsed {
    return maxTextureIndex + 1;
  }

  void copyActor(Actor actor) {
    maxTextureIndex = actor.maxTextureIndex;
    _artboardCount = actor._artboardCount;
    if (_artboardCount > 0) {
      int idx = 0;
      _artboards = List<ActorArtboard>(_artboardCount);
      for (ActorArtboard artboard in actor._artboards) {
        if (artboard == null) {
          _artboards[idx++] = null;
          continue;
        }
        ActorArtboard instanceArtboard = artboard.makeInstance();
        _artboards[idx++] = instanceArtboard;
      }
    }
  }

  ActorArtboard makeArtboard() {
    return ActorArtboard(this);
  }

  ActorImage makeImageNode() {
    return ActorImage();
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

  Future<bool> load(ByteData data, FlareAnimationProvider provider) async {
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
      var jsonActor = jsonDecode(stringData);
      Map jsonObject = Map();
      jsonObject["container"] = jsonActor;
      inputData = jsonObject;
    }

    StreamReader reader = StreamReader(inputData);
    _version = reader.readVersion();

    StreamReader block;
    while ((block = reader.readNextBlock(BlockTypesMap)) != null) {
      switch (block.blockType) {
        case BlockTypes.Artboards:
          readArtboardsBlock(block);
          break;

        case BlockTypes.Atlases:
          List<Uint8List> rawAtlases = await readAtlasesBlock(block, provider);
          success = await loadAtlases(rawAtlases);
          break;
      }
    }

    return success;
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
            ActorArtboard artboard = makeArtboard();
            artboard.read(artboardBlock);
            _artboards[artboardIndex] = artboard;
            break;
          }
      }
    }
  }

  Future<Uint8List> readOutOfBandAsset(String fileName, FlareAnimationProvider provider);

  Future<List<Uint8List>> readAtlasesBlock(
      StreamReader block, FlareAnimationProvider provider) {
    // Determine whether or not the atlas is in or out of band.
    bool isOOB = block.readBool("isOOB");
    block.openArray("data");
    int numAtlases = block.readUint16Length();
    if (isOOB) {
      List<Future<Uint8List>> waitingFor = List<Future<Uint8List>>(numAtlases);
      for (int i = 0; i < numAtlases; i++) {
        waitingFor[i] = readOutOfBandAsset(block.readString("data"),provider);
      }
      return Future.wait(waitingFor);
    } else {
      // This is sync.
      List<Uint8List> inBandAssets = List<Uint8List>(numAtlases);
      for (int i = 0; i < numAtlases; i++) {
        inBandAssets[i] = block.readAsset();
      }
      Completer<List<Uint8List>> completer = Completer<List<Uint8List>>();
      completer.complete(inBandAssets);
      return completer.future;
    }

    // for(int i = 0; i < numAtlases; i++)
    // {
    //   if(isOOB)
    //   {

    // 	  // Read from assets
    //   }
    //   else
    //   {
    // 	  // Read from data block.
    // 	  block.readUint32("length");
    //   }
    // }
    block.closeArray();
  }
}
