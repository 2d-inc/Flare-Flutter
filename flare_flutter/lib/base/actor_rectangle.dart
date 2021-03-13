import 'dart:math';

import 'package:flare_flutter/base/actor_artboard.dart';
import 'package:flare_flutter/base/actor_component.dart';
import 'package:flare_flutter/base/actor_node.dart';
import 'package:flare_flutter/base/actor_path.dart';
import 'package:flare_flutter/base/math/vec2d.dart';
import 'package:flare_flutter/base/path_point.dart';
import 'package:flare_flutter/base/stream_reader.dart';

class ActorRectangle extends ActorProceduralPath {
  double _radius = 0.0;

  bool get doesDraw {
    return !renderCollapsed;
  }

  bool get isClosed => true;

  @override
  List<PathPoint> get points {
    double halfWidth = width / 2;
    double halfHeight = height / 2;
    double renderRadius = min(_radius, min(halfWidth, halfHeight));
    List<PathPoint> _rectanglePathPoints = <PathPoint>[];
    _rectanglePathPoints.add(StraightPathPoint.fromValues(
        Vec2D.fromValues(-halfWidth, -halfHeight), renderRadius));
    _rectanglePathPoints.add(StraightPathPoint.fromValues(
        Vec2D.fromValues(halfWidth, -halfHeight), renderRadius));
    _rectanglePathPoints.add(StraightPathPoint.fromValues(
        Vec2D.fromValues(halfWidth, halfHeight), renderRadius));
    _rectanglePathPoints.add(StraightPathPoint.fromValues(
        Vec2D.fromValues(-halfWidth, halfHeight), renderRadius));

    return _rectanglePathPoints;
  }

  double get radius => _radius;

  set radius(double rd) {
    if (rd != _radius) {
      _radius = rd;
      invalidateDrawable();
    }
  }

  void copyRectangle(ActorRectangle node, ActorArtboard resetArtboard) {
    copyPath(node, resetArtboard);
    _radius = node._radius;
  }

  @override
  void invalidatePath() {}

  @override
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    ActorRectangle instance = ActorRectangle();
    instance.copyRectangle(this, resetArtboard);
    return instance;
  }

  static ActorRectangle read(
      ActorArtboard artboard, StreamReader reader, ActorRectangle component) {
    ActorNode.read(artboard, reader, component);

    component.width = reader.readFloat32('width');
    component.height = reader.readFloat32('height');
    component._radius = reader.readFloat32('cornerRadius');
    return component;
  }
}
