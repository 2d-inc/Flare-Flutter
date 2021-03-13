import 'package:flare_flutter/base/actor_artboard.dart';
import 'package:flare_flutter/base/actor_targeted_constraint.dart';
import 'package:flare_flutter/base/stream_reader.dart';
import 'package:flare_flutter/base/transform_space.dart';

abstract class ActorAxisConstraint extends ActorTargetedConstraint {
  bool _copyX = false;
  bool _copyY = false;
  bool _enableMinX = false;
  bool _enableMaxX = false;
  bool _enableMinY = false;
  bool _enableMaxY = false;
  bool _offset = false;

  double _scaleX = 1.0;
  double _scaleY = 1.0;
  double _minX = 0.0;
  double _maxX = 0.0;
  double _minY = 0.0;
  double _maxY = 0.0;

  int _sourceSpace = TransformSpace.world;
  int _destSpace = TransformSpace.world;
  int _minMaxSpace = TransformSpace.world;

  ActorAxisConstraint() : super();

  static ActorAxisConstraint read(ActorArtboard artboard, StreamReader reader,
      ActorAxisConstraint component) {
    ActorTargetedConstraint.read(artboard, reader, component);
    component._copyX = reader.readBool('copyX');
    if (component._copyX) {
      component._scaleX = reader.readFloat32('scaleX');
    }

    component._enableMinX = reader.readBool('enableMinX');
    if (component._enableMinX) {
      component._minX = reader.readFloat32('minX');
    }

    component._enableMaxX = reader.readBool('enableMaxX');
    if (component._enableMaxX) {
      component._maxX = reader.readFloat32('maxX');
    }

    component._copyY = reader.readBool('copyY');
    if (component._copyY) {
      component._scaleY = reader.readFloat32('scaleY');
    }

    component._enableMinY = reader.readBool('enableMinY');
    if (component._enableMinY) {
      component._minY = reader.readFloat32('minY');
    }

    component._enableMaxY = reader.readBool('enableMaxY');
    if (component._enableMaxY) {
      component._maxY = reader.readFloat32('maxY');
    }

    component._offset = reader.readBool('offset');
    component._sourceSpace = reader.readUint8('sourceSpaceId');
    component._destSpace = reader.readUint8('destSpaceId');
    component._minMaxSpace = reader.readUint8('minMaxSpaceId');

    return component;
  }

  void copyAxisConstraint(
      ActorAxisConstraint node, ActorArtboard resetArtboard) {
    copyTargetedConstraint(node, resetArtboard);

    _copyX = node._copyX;
    _copyY = node._copyY;
    _enableMinX = node._enableMinX;
    _enableMaxX = node._enableMaxX;
    _enableMinY = node._enableMinY;
    _enableMaxY = node._enableMaxY;
    _offset = node._offset;

    _scaleX = node._scaleX;
    _scaleY = node._scaleY;
    _minX = node._minX;
    _maxX = node._maxX;
    _minY = node._minY;
    _maxY = node._maxY;

    _sourceSpace = node._sourceSpace;
    _destSpace = node._destSpace;
    _minMaxSpace = node._minMaxSpace;
  }

  @override
  void onDirty(int dirt) {
    markDirty();
  }

  bool get copyX => _copyX;
  bool get copyY => _copyY;
  int get destSpace => _destSpace;
  bool get enableMaxX => _enableMaxX;
  bool get enableMaxY => _enableMaxY;
  bool get enableMinX => _enableMinX;
  bool get enableMinY => _enableMinY;
  double get maxX => _maxX;
  double get maxY => _maxY;
  int get minMaxSpace => _minMaxSpace;
  double get minX => _minX;
  double get minY => _minY;
  bool get offset => _offset;
  double get scaleX => _scaleX;
  double get scaleY => _scaleY;
  int get sourceSpace => _sourceSpace;
}
