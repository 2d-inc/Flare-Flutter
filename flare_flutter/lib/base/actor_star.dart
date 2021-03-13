import 'dart:math';

import 'package:flare_flutter/base/actor_artboard.dart';
import 'package:flare_flutter/base/actor_component.dart';
import 'package:flare_flutter/base/actor_node.dart';
import 'package:flare_flutter/base/actor_path.dart';
import 'package:flare_flutter/base/math/vec2d.dart';
import 'package:flare_flutter/base/path_point.dart';
import 'package:flare_flutter/base/stream_reader.dart';

class ActorStar extends ActorProceduralPath {
  int _numPoints = 5;
  double _innerRadius = 0.0;

  bool get doesDraw => !renderCollapsed;

  double get innerRadius => _innerRadius;

  set innerRadius(double val) {
    if (val != _innerRadius) {
      _innerRadius = val;
      invalidateDrawable();
    }
  }

  bool get isClosed => true;

  int get numPoints => _numPoints;

  @override
  List<PathPoint> get points {
    List<PathPoint> _starPoints = <PathPoint>[
      StraightPathPoint.fromTranslation(Vec2D.fromValues(0.0, -radiusY))
    ];

    double angle = -pi / 2.0;
    double inc = (pi * 2.0) / sides;
    Vec2D sx = Vec2D.fromValues(radiusX, radiusX * _innerRadius);
    Vec2D sy = Vec2D.fromValues(radiusY, radiusY * _innerRadius);

    for (int i = 0; i < sides; i++) {
      _starPoints.add(StraightPathPoint.fromTranslation(
          Vec2D.fromValues(cos(angle) * sx[i % 2], sin(angle) * sy[i % 2])));
      angle += inc;
    }
    return _starPoints;
  }

  double get radiusX => width / 2;

  double get radiusY => height / 2;
  int get sides => _numPoints * 2;
  void copyStar(ActorStar node, ActorArtboard resetArtboard) {
    copyPath(node, resetArtboard);
    _numPoints = node._numPoints;
    _innerRadius = node._innerRadius;
  }
  @override
  void invalidatePath() {}
  @override
  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    ActorStar instance = ActorStar();
    instance.copyStar(this, resetArtboard);
    return instance;
  }
  static ActorStar read(
      ActorArtboard artboard, StreamReader reader, ActorStar component) {
    ActorNode.read(artboard, reader, component);

    component.width = reader.readFloat32('width');
    component.height = reader.readFloat32('height');
    component._numPoints = reader.readUint32('points');
    component._innerRadius = reader.readFloat32('innerRadius');
    return component;
  }
}
