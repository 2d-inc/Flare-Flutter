import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flare_flutter/base/actor_artboard.dart';
import 'package:flare_flutter/base/actor_color.dart';
import 'package:flare_flutter/base/actor_drop_shadow.dart';
import 'package:flare_flutter/base/actor_ellipse.dart';
import 'package:flare_flutter/base/actor_image.dart';
import 'package:flare_flutter/base/actor_inner_shadow.dart';
import 'package:flare_flutter/base/actor_layer_effect_renderer.dart';
import 'package:flare_flutter/base/actor_path.dart';
import 'package:flare_flutter/base/actor_polygon.dart';
import 'package:flare_flutter/base/actor_rectangle.dart';
import 'package:flare_flutter/base/actor_shape.dart';
import 'package:flare_flutter/base/actor_star.dart';
import 'package:flare_flutter/base/actor_triangle.dart';
import 'package:flare_flutter/base/block_types.dart';
import 'package:flare_flutter/base/stream_reader.dart';

abstract class Actor {
  int maxTextureIndex = 0;
  int _version = 0;
  late List<ActorArtboard?> _artboards;

  Actor();

  ActorArtboard? get artboard =>
      _artboards.isNotEmpty ? _artboards.first : null;
  int get texturesUsed {
    return maxTextureIndex + 1;
  }

  int get version {
    return _version;
  }

  void copyActor(Actor actor) {
    maxTextureIndex = actor.maxTextureIndex;
    int artboardCount = actor._artboards.length;
    if (artboardCount > 0) {
      _artboards = <ActorArtboard?>[];
      for (final ActorArtboard? artboard in actor._artboards) {
        _artboards.add(artboard?.makeInstanceWithActor(this));
      }
    }
  }

  ActorArtboard? getArtboard([String? name]) => name == null
      ? artboard
      : _artboards.firstWhereOrNull((artboard) => artboard?.name == name);

  Future<bool> load(ByteData data, dynamic context) async {
    if (data.lengthInBytes < 5) {
      throw UnsupportedError('Not a valid Flare file.');
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
      Map jsonObject = <dynamic, dynamic>{};
      jsonObject['container'] = jsonActor;
      inputData = jsonObject;
    }

    StreamReader reader = StreamReader(inputData);
    _version = reader.readVersion();

    StreamReader? block;
    while ((block = reader.readNextBlock(blockTypesMap)) != null) {
      switch (block!.blockType) {
        case BlockTypes.artboards:
          readArtboardsBlock(block);
          break;

        case BlockTypes.atlases:
          List<Uint8List> rawAtlases = await readAtlasesBlock(block, context);
          success = await loadAtlases(rawAtlases);
          break;
      }
    }

    // Resolve now.
    for (final ActorArtboard? artboard in _artboards) {
      artboard!.resolveHierarchy();
    }
    for (final ActorArtboard? artboard in _artboards) {
      artboard!.completeResolveHierarchy();
    }

    for (final ActorArtboard? artboard in _artboards) {
      artboard!.sortDependencies();
    }

    return success;
  }

  Future<bool> loadAtlases(List<Uint8List> rawAtlases);

  // ignore: use_to_and_as_if_applicable
  ActorArtboard makeArtboard() => ActorArtboard(this);

  ColorFill makeColorFill();

  ColorStroke makeColorStroke();

  ActorDropShadow makeDropShadow();

  ActorEllipse makeEllipse() {
    return ActorEllipse();
  }

  GradientFill makeGradientFill();

  GradientStroke makeGradientStroke();

  ActorImage makeImageNode() {
    return ActorImage();
  }

  ActorInnerShadow makeInnerShadow();

  ActorLayerEffectRenderer makeLayerEffectRenderer();

  ActorPath makePathNode() {
    return ActorPath();
  }

  ActorPolygon makePolygon() {
    return ActorPolygon();
  }

  RadialGradientFill makeRadialFill();

  RadialGradientStroke makeRadialStroke();

  ActorRectangle makeRectangle() {
    return ActorRectangle();
  }

  ActorShape makeShapeNode(ActorShape? source) {
    return ActorShape();
  }

  ActorStar makeStar() {
    return ActorStar();
  }

  ActorTriangle makeTriangle() {
    return ActorTriangle();
  }

  void readArtboardsBlock(StreamReader block) {
    int artboardCount = block.readUint16Length();
    _artboards = List<ActorArtboard?>.filled(artboardCount, null);

    for (int artboardIndex = 0, end = _artboards.length;
        artboardIndex < end;
        artboardIndex++) {
      StreamReader? artboardBlock = block.readNextBlock(blockTypesMap);
      if (artboardBlock == null) {
        break;
      }
      switch (artboardBlock.blockType) {
        case BlockTypes.actorArtboard:
          {
            ActorArtboard artboard = makeArtboard();
            artboard.read(artboardBlock);
            _artboards[artboardIndex] = artboard;
            break;
          }
      }
    }
  }

  Future<List<Uint8List>> readAtlasesBlock(
      StreamReader block, dynamic context) {
    // Determine whether or not the atlas is in or out of band.
    bool isOOB = block.readBool('isOOB');
    block.openArray('data');
    int numAtlases = block.readUint16Length();
    Future<List<Uint8List>> result;
    if (isOOB) {
      List<Future<Uint8List>> waitingFor = <Future<Uint8List>>[];
      for (int i = 0; i < numAtlases; i++) {
        waitingFor.add(readOutOfBandAsset(block.readString('data'), context));
      }
      result = Future.wait(waitingFor);
    } else {
      // This is sync.
      List<Uint8List> inBandAssets = <Uint8List>[];
      for (int i = 0; i < numAtlases; i++) {
        inBandAssets.add(block.readAsset());
      }
      Completer<List<Uint8List>> completer = Completer<List<Uint8List>>();
      completer.complete(inBandAssets);
      result = completer.future;
    }
    block.closeArray();
    return result;
  }

  Future<Uint8List> readOutOfBandAsset(String filename, dynamic context);
}
