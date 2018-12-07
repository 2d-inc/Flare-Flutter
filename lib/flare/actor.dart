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

class Actor {
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

  ColorFill makeColorFill() {
    return ColorFill();
  }

  ColorStroke makeColorStroke() {
    return ColorStroke();
  }

  GradientFill makeGradientFill() {
    return GradientFill();
  }

  GradientStroke makeGradientStroke() {
    return GradientStroke();
  }

  RadialGradientFill makeRadialFill() {
    return RadialGradientFill();
  }

  RadialGradientStroke makeRadialStroke() {
    return RadialGradientStroke();
  }

  void load(ByteData data) {
    if (data.lengthInBytes < 5) {
      throw UnsupportedError("Not a valid Flare file.");
    }
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
            ActorArtboard artboard = makeArtboard();
            artboard.read(artboardBlock);
            _artboards[artboardIndex] = artboard;
            break;
          }
      }
    }
  }
}
