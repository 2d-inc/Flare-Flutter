import "actor_artboard.dart";
import "actor_targeted_constraint.dart";
import "transform_space.dart";
import "stream_reader.dart";

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

  int _sourceSpace = TransformSpace.World;
  int _destSpace = TransformSpace.World;
  int _minMaxSpace = TransformSpace.World;

  ActorAxisConstraint() : super();

  static ActorAxisConstraint read(ActorArtboard artboard, StreamReader reader,
      ActorAxisConstraint component) {
    ActorTargetedConstraint.read(artboard, reader, component);
    component._copyX = reader.readBool("copyX");
    if (component._copyX) {
      component._scaleX = reader.readFloat32("scaleX");
    }

    component._enableMinX = reader.readBool("enableMinX");
    if (component._enableMinX) {
      component._minX = reader.readFloat32("minX");
    }

    component._enableMaxX = reader.readBool("enableMaxX");
    if (component._enableMaxX) {
      component._maxX = reader.readFloat32("maxX");
    }

    component._copyY = reader.readBool("copyY");
    if (component._copyY) {
      component._scaleY = reader.readFloat32("scaleY");
    }

    component._enableMinY = reader.readBool("enableMinY");
    if (component._enableMinY) {
      component._minY = reader.readFloat32("minY");
    }

    component._enableMaxY = reader.readBool("enableMaxY");
    if (component._enableMaxY) {
      component._maxY = reader.readFloat32("maxY");
    }

    component._offset = reader.readBool("offset");
    component._sourceSpace = reader.readUint8("sourceSpaceId");
    component._destSpace = reader.readUint8("destSpaceId");
    component._minMaxSpace = reader.readUint8("minMaxSpaceId");

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
  onDirty(int dirt) {
    markDirty();
  }

  get copyX => _copyX;
  get copyY => _copyY;
  get destSpace => _destSpace;
  get enableMaxX => _enableMaxX;
  get enableMaxY => _enableMaxY;
  get enableMinX => _enableMinX;
  get enableMinY => _enableMinY;
  get maxX => _maxX;
  get maxY => _maxY;
  get minMaxSpace => _minMaxSpace;
  get minX => _minX;
  get minY => _minY;
  get offset => _offset;
  get scaleX => _scaleX;
  get scaleY => _scaleY;
  get sourceSpace => _sourceSpace;
}
