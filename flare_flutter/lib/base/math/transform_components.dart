import 'dart:typed_data';

import 'package:flare_flutter/base/math/vec2d.dart';

class TransformComponents {
  final Float32List _buffer;

  TransformComponents()
      : _buffer = Float32List.fromList([1.0, 0.0, 0.0, 1.0, 0.0, 0.0]);

  TransformComponents.clone(TransformComponents copy)
      : _buffer = Float32List.fromList(copy.values);

  double get rotation {
    return _buffer[4];
  }

  set rotation(double value) {
    _buffer[4] = value;
  }

  Vec2D get scale {
    return Vec2D.fromValues(_buffer[2], _buffer[3]);
  }

  double get scaleX {
    return _buffer[2];
  }

  set scaleX(double value) {
    _buffer[2] = value;
  }

  double get scaleY {
    return _buffer[3];
  }

  set scaleY(double value) {
    _buffer[3] = value;
  }

  double get skew {
    return _buffer[5];
  }

  set skew(double value) {
    _buffer[5] = value;
  }

  Vec2D get translation {
    return Vec2D.fromValues(_buffer[0], _buffer[1]);
  }

  Float32List get values {
    return _buffer;
  }

  double get x {
    return _buffer[0];
  }

  set x(double value) {
    _buffer[0] = value;
  }

  double get y {
    return _buffer[1];
  }

  set y(double value) {
    _buffer[1] = value;
  }

  double operator [](int index) {
    return _buffer[index];
  }

  void operator []=(int index, double value) {
    _buffer[index] = value;
  }
}
