import 'dart:math';

import 'package:flare_flutter/base/actor_artboard.dart';
import 'package:flare_flutter/base/actor_bone.dart';
import 'package:flare_flutter/base/actor_component.dart';
import 'package:flare_flutter/base/actor_constraint.dart';
import 'package:flare_flutter/base/actor_jelly_bone.dart';
import 'package:flare_flutter/base/actor_node.dart';
import 'package:flare_flutter/base/actor_root_bone.dart';
import 'package:flare_flutter/base/math/mat2d.dart';
import 'package:flare_flutter/base/math/vec2d.dart';
import 'package:flare_flutter/base/stream_reader.dart';

class JellyComponent extends ActorComponent {
  static const int jellyMax = 16;
  static double optimalDistance = 4.0 * (sqrt(2.0) - 1.0) / 3.0;
  static double curveConstant = optimalDistance * sqrt(2.0) * 0.5;
  static const double epsilon = 0.001; // Intentionally agressive.

  late double _easeIn;

  late double _easeOut;

  late double _scaleIn;

  late double _scaleOut;
  late int _inTargetIdx;
  late int _outTargetIdx;
  ActorNode? _inTarget;
  ActorNode? _outTarget;
  List<ActorJellyBone>? _bones;
  final Vec2D _inPoint = Vec2D();
  final Vec2D _inDirection = Vec2D();
  final Vec2D _outPoint = Vec2D();
  final Vec2D _outDirection = Vec2D();
  final Vec2D _cachedTip = Vec2D();
  final Vec2D _cachedOut = Vec2D();
  final Vec2D _cachedIn = Vec2D();

  double? _cachedScaleIn;
  double? _cachedScaleOut;
  final List<Vec2D> _jellyPoints = List<Vec2D>.filled(jellyMax + 1, Vec2D());
  ActorNode? get inTarget => _inTarget;
  ActorNode? get outTarget => _inTarget;

  @override
  void completeResolve() {
    //super.completeResolve();
    ActorBone bone = parent as ActorBone;
    bone.jelly = this;

    // Get jellies.
    var children = bone.children;
    if (children == null) {
      return;
    }

    _bones = <ActorJellyBone>[];
    for (final child in children) {
      if (child is ActorJellyBone) {
        _bones!.add(child);
        // Make sure the jelly doesn't update until
        // the jelly component has updated
        artboard.addDependency(child, this);
      }
    }
  }

  void copyJelly(JellyComponent component, ActorArtboard artboard) {
    super.copyComponent(component, artboard);
    _easeIn = component._easeIn;
    _easeOut = component._easeOut;
    _scaleIn = component._scaleIn;
    _scaleOut = component._scaleOut;
    _inTargetIdx = component._inTargetIdx;
    _outTargetIdx = component._outTargetIdx;
  }
  @override
  ActorComponent makeInstance(ActorArtboard artboard) {
    JellyComponent instance = JellyComponent();
    instance.copyJelly(this, artboard);
    return instance;
  }

  List<Vec2D> normalizeCurve(List<Vec2D> curve, int numSegments) {
    List<Vec2D> points = <Vec2D>[];
    int curvePointCount = curve.length;
    List<double> distances = List<double>.filled(curvePointCount, 0.0);
    for (int i = 0; i < curvePointCount - 1; i++) {
      Vec2D p1 = curve[i];
      Vec2D p2 = curve[i + 1];
      distances[i + 1] = distances[i] + Vec2D.distance(p1, p2);
    }
    double totalDistance = distances.last;

    double segmentLength = totalDistance / numSegments;
    int pointIndex = 1;
    for (int i = 1; i <= numSegments; i++) {
      double distance = segmentLength * i;

      while (pointIndex < curvePointCount - 1 &&
          distances[pointIndex] < distance) {
        pointIndex++;
      }

      double d = distances[pointIndex];
      double lastCurveSegmentLength = d - distances[pointIndex - 1];
      double remainderOfDesired = d - distance;
      double ratio = remainderOfDesired / lastCurveSegmentLength;
      double iratio = 1.0 - ratio;

      Vec2D p1 = curve[pointIndex - 1];
      Vec2D p2 = curve[pointIndex];
      points.add(Vec2D.fromValues(
          p1[0] * ratio + p2[0] * iratio, p1[1] * ratio + p2[1] * iratio));
    }

    return points;
  }

  @override
  void onDirty(int dirt) {
    // Intentionally empty. Doesn't throw dirt around.
  }

  @override
  void resolveComponentIndices(List<ActorComponent?> components) {
    super.resolveComponentIndices(components);

    if (_inTargetIdx != 0) {
      _inTarget = components[_inTargetIdx] as ActorNode?;
    }
    if (_outTargetIdx != 0) {
      _outTarget = components[_outTargetIdx] as ActorNode?;
    }

    List<ActorConstraint> dependencyConstraints = <ActorConstraint>[];
    ActorBone? bone = parent as ActorBone?;
    if (bone != null) {
      artboard.addDependency(this, bone);
      dependencyConstraints += bone.allConstraints;
      ActorBone? firstBone = bone.firstBone;
      if (firstBone != null) {
        artboard.addDependency(this, firstBone);
        dependencyConstraints += firstBone.allConstraints;

        // If we don't have an out target and the child jelly does have an
        // in target we are dependent on that target's position.
        if (_outTarget == null &&
            firstBone.jelly != null &&
            firstBone.jelly!.inTarget != null) {
          artboard.addDependency(this, firstBone.jelly!.inTarget!);
          dependencyConstraints += firstBone.jelly!.inTarget!.allConstraints;
        }
      }
      if (bone.parent is ActorBone) {
        ActorBone parentBone = bone.parent as ActorBone;
        JellyComponent? parentBoneJelly = parentBone.jelly;
        if (parentBoneJelly != null && parentBoneJelly.outTarget != null) {
          artboard.addDependency(this, parentBoneJelly.outTarget!);
          dependencyConstraints += parentBoneJelly.outTarget!.allConstraints;
        }
      }
    }

    if (_inTarget != null) {
      artboard.addDependency(this, _inTarget!);
      dependencyConstraints += _inTarget!.allConstraints;
    }
    if (_outTarget != null) {
      artboard.addDependency(this, _outTarget!);
      dependencyConstraints += _outTarget!.allConstraints;
    }

    // We want to depend on any and all constraints that our dependents have.
    Set<ActorConstraint> constraints =
        Set<ActorConstraint>.from(dependencyConstraints);
    for (final ActorConstraint constraint in constraints) {
      artboard.addDependency(this, constraint);
    }
  }

  @override
  void update(int dirt) {
    ActorBone bone = parent as ActorBone;
    ActorNode? parentBone = bone.parent;
    JellyComponent? parentBoneJelly;
    if (parentBone is ActorBone) {
      parentBoneJelly = parentBone.jelly;
    }

    Mat2D inverseWorld = Mat2D();
    if (!Mat2D.invert(inverseWorld, bone.worldTransform)) {
      return;
    }

    if (_inTarget != null) {
      Vec2D translation = _inTarget!.getWorldTranslation(Vec2D());
      Vec2D.transformMat2D(_inPoint, translation, inverseWorld);
      Vec2D.normalize(_inDirection, _inPoint);
    } else if (parentBone != null) {
      ActorBone? firstBone;
      if (parentBone is ActorBone) {
        firstBone = parentBone.firstBone;
      } else if (parentBone is ActorRootBone) {
        firstBone = parentBone.firstBone;
      }
      if (firstBone == bone &&
          parentBoneJelly != null &&
          parentBoneJelly._outTarget != null) {
        Vec2D translation =
            parentBoneJelly._outTarget!.getWorldTranslation(Vec2D());
        Vec2D localParentOut =
            Vec2D.transformMat2D(Vec2D(), translation, inverseWorld);
        Vec2D.normalize(localParentOut, localParentOut);
        Vec2D.negate(_inDirection, localParentOut);
      } else {
        Vec2D d1 = Vec2D.fromValues(1.0, 0.0);
        Vec2D d2 = Vec2D.fromValues(1.0, 0.0);

        Vec2D.transformMat2(d1, d1, parentBone.worldTransform);
        Vec2D.transformMat2(d2, d2, bone.worldTransform);

        Vec2D sum = Vec2D.add(Vec2D(), d1, d2);
        Vec2D.transformMat2(_inDirection, sum, inverseWorld);
        Vec2D.normalize(_inDirection, _inDirection);
      }
      _inPoint[0] = _inDirection[0] * _easeIn * bone.length * curveConstant;
      _inPoint[1] = _inDirection[1] * _easeIn * bone.length * curveConstant;
    } else {
      _inDirection[0] = 1.0;
      _inDirection[1] = 0.0;
      _inPoint[0] = _inDirection[0] * _easeIn * bone.length * curveConstant;
    }

    if (_outTarget != null) {
      Vec2D translation = _outTarget!.getWorldTranslation(Vec2D());
      Vec2D.transformMat2D(_outPoint, translation, inverseWorld);
      Vec2D tip = Vec2D.fromValues(bone.length, 0.0);
      Vec2D.subtract(_outDirection, _outPoint, tip);
      Vec2D.normalize(_outDirection, _outDirection);
    } else if (bone.firstBone != null) {
      ActorBone firstBone = bone.firstBone!;
      JellyComponent? firstBoneJelly = firstBone.jelly;
      if (firstBoneJelly != null && firstBoneJelly._inTarget != null) {
        Vec2D translation =
            firstBoneJelly._inTarget!.getWorldTranslation(Vec2D());
        Vec2D worldChildInDir = Vec2D.subtract(
            Vec2D(), firstBone.getWorldTranslation(Vec2D()), translation);
        Vec2D.transformMat2(_outDirection, worldChildInDir, inverseWorld);
      } else {
        Vec2D d1 = Vec2D.fromValues(1.0, 0.0);
        Vec2D d2 = Vec2D.fromValues(1.0, 0.0);

        Vec2D.transformMat2(d1, d1, firstBone.worldTransform);
        Vec2D.transformMat2(d2, d2, bone.worldTransform);

        Vec2D sum = Vec2D.add(Vec2D(), d1, d2);
        Vec2D negativeSum = Vec2D.negate(Vec2D(), sum);
        Vec2D.transformMat2(_outDirection, negativeSum, inverseWorld);
        Vec2D.normalize(_outDirection, _outDirection);
      }
      Vec2D.normalize(_outDirection, _outDirection);
      Vec2D scaledOut = Vec2D.scale(
          Vec2D(), _outDirection, _easeOut * bone.length * curveConstant);
      _outPoint[0] = bone.length;
      _outPoint[1] = 0.0;
      Vec2D.add(_outPoint, _outPoint, scaledOut);
    } else {
      _outDirection[0] = -1.0;
      _outDirection[1] = 0.0;

      Vec2D scaledOut = Vec2D.scale(
          Vec2D(), _outDirection, _easeOut * bone.length * curveConstant);
      _outPoint[0] = bone.length;
      _outPoint[1] = 0.0;
      Vec2D.add(_outPoint, _outPoint, scaledOut);
    }

    updateJellies();
  }

  // ignore: prefer_constructors_over_static_methods
  void updateJellies() {
    if (_bones == null) {
      return;
    }
    ActorBone bone = parent as ActorBone;
    // We are in local bone space.
    Vec2D tipPosition = Vec2D.fromValues(bone.length, 0.0);

    if (fuzzyEquals(_cachedTip, tipPosition) &&
        fuzzyEquals(_cachedOut, _outPoint) &&
        fuzzyEquals(_cachedIn, _inPoint) &&
        _cachedScaleIn == _scaleIn &&
        _cachedScaleOut == _scaleOut) {
      return;
    }

    Vec2D.copy(_cachedTip, tipPosition);
    Vec2D.copy(_cachedOut, _outPoint);
    Vec2D.copy(_cachedIn, _inPoint);
    _cachedScaleIn = _scaleIn;
    _cachedScaleOut = _scaleOut;

    Vec2D q0 = Vec2D();
    Vec2D q1 = _inPoint;
    Vec2D q2 = _outPoint;
    Vec2D q3 = tipPosition;

    forwardDiffBezier(q0[0], q1[0], q2[0], q3[0], _jellyPoints, jellyMax, 0);
    forwardDiffBezier(q0[1], q1[1], q2[1], q3[1], _jellyPoints, jellyMax, 1);

    List<Vec2D> normalizedPoints = normalizeCurve(_jellyPoints, _bones!.length);

    Vec2D lastPoint = _jellyPoints[0];

    double scale = _scaleIn;
    double scaleInc = (_scaleOut - _scaleIn) / (_bones!.length - 1);
    for (int i = 0; i < normalizedPoints.length; i++) {
      ActorJellyBone jelly = _bones![i];
      Vec2D p = normalizedPoints[i];

      jelly.translation = lastPoint;
      jelly.length = Vec2D.distance(p, lastPoint);
      jelly.scaleY = scale;
      scale += scaleInc;

      Vec2D diff = Vec2D.subtract(Vec2D(), p, lastPoint);
      jelly.rotation = atan2(diff[1], diff[0]);
      lastPoint = p;
    }
  }

  static void forwardDiffBezier(double c0, double c1, double c2, double c3,
      List<Vec2D> points, int count, int offset) {
    double f = count.toDouble();

    double p0 = c0;

    double p1 = 3.0 * (c1 - c0) / f;

    f *= count;
    double p2 = 3.0 * (c0 - 2.0 * c1 + c2) / f;

    f *= count;
    double p3 = (c3 - c0 + 3.0 * (c1 - c2)) / f;

    // ignore: parameter_assignments
    c0 = p0;
    // ignore: parameter_assignments
    c1 = p1 + p2 + p3;
    // ignore: parameter_assignments
    c2 = 2 * p2 + 6 * p3;
    // ignore: parameter_assignments
    c3 = 6 * p3;

    for (int a = 0; a <= count; a++) {
      points[a][offset] = c0;
      // ignore: parameter_assignments
      c0 += c1;
      // ignore: parameter_assignments
      c1 += c2;
      // ignore: parameter_assignments
      c2 += c3;
    }
  }

  static bool fuzzyEquals(Vec2D a, Vec2D b) {
    double a0 = a[0], a1 = a[1];
    double b0 = b[0], b1 = b[1];
    return (a0 - b0).abs() <= epsilon * max(1.0, max(a0.abs(), b0.abs())) &&
        (a1 - b1).abs() <= epsilon * max(1.0, max(a1.abs(), b1.abs()));
  }

  // ignore: prefer_constructors_over_static_methods
  static JellyComponent read(
      ActorArtboard artboard, StreamReader reader, JellyComponent? node) {
    // ignore: parameter_assignments
    node ??= JellyComponent();
    ActorComponent.read(artboard, reader, node);

    node._easeIn = reader.readFloat32('easeIn');
    node._easeOut = reader.readFloat32('easeOut');
    node._scaleIn = reader.readFloat32('scaleIn');
    node._scaleOut = reader.readFloat32('scaleOut');
    node._inTargetIdx = reader.readId('inTargetId');
    node._outTargetIdx = reader.readId('outTargetId');

    return node;
  }
}
