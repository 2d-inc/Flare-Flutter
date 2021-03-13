import 'dart:typed_data';

import 'package:flare_flutter/base/actor_artboard.dart';
import 'package:flare_flutter/base/actor_blur.dart';
import 'package:flare_flutter/base/stream_reader.dart';

abstract class ActorShadow extends ActorBlur {
  late double offsetX;
  late double offsetY;
  Float32List _color = Float32List(4);
  int get blendModeId;
  set blendModeId(int value);

  Float32List get color => _color;

  void copyShadow(ActorShadow from, ActorArtboard resetArtboard) {
    copyBlur(from, resetArtboard);
    offsetX = from.offsetX;
    offsetY = from.offsetY;
    _color[0] = from._color[0];
    _color[1] = from._color[1];
    _color[2] = from._color[2];
    _color[3] = from._color[3];
    blendModeId = from.blendModeId;
  }

  static ActorShadow read(
      ActorArtboard artboard, StreamReader reader, ActorShadow component) {
    ActorBlur.read(artboard, reader, component);
    component.offsetX = reader.readFloat32('offsetX');
    component.offsetY = reader.readFloat32('offsetY');
    component._color = reader.readFloat32Array(4, 'color');
    component.blendModeId = reader.readUint8('blendMode');
    return component;
  }
}
