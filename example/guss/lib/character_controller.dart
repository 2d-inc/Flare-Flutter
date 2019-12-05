import 'dart:math';
import 'dart:ui';

import 'package:flare_flutter/flare.dart';
import 'package:flare_dart/math/mat2d.dart';
import 'package:flare_dart/math/vec2d.dart';
import 'package:flare_flutter/flare_controls.dart';

class CharacterController extends FlareControls {
  // Store a reference to our face control node (the "ctrl_look" node in Flare)
  ActorNode _faceControl;

  // Storage for our matrix to get global Flutter coordinates into Flare world
  // coordinates.
  final Mat2D _globalToFlareWorld = Mat2D();

  // Caret in Flutter global coordinates.
  final Vec2D _caretGlobal = Vec2D();

  // Caret in Flare world coordinates.
  final Vec2D _caretWorld = Vec2D();

  // Store the origin in both world and local transform spaces.
  final Vec2D _faceOrigin = Vec2D();
  final Vec2D _faceOriginLocal = Vec2D();

  // We store the idle animation as we always apply it first, before any other
  // animation.
  ActorAnimation _idleAnimation;
  double _idleTime = 0;

  String _coverEyesIn, _coverEyesOut;
  bool _hasFocus = false;

  // Project gaze forward by this many pixels.
  final double projectGaze;

  CharacterController({this.projectGaze = 60.0});

  @override
  bool advance(FlutterActorArtboard artboard, double elapsed) {
    _idleTime = (_idleTime + elapsed) % _idleAnimation.duration;
    _idleAnimation.apply(_idleTime, artboard, 1.0);
    super.advance(artboard, elapsed);
    Vec2D targetTranslation;
    if (_hasFocus) {
      // Get caret in Flare world space.
      Vec2D.transformMat2D(_caretWorld, _caretGlobal, _globalToFlareWorld);

      // To make it more interesting, we'll also add a sinusoidal
      // vertical offset.
      _caretWorld[1] +=
          sin(DateTime.now().millisecondsSinceEpoch / 300.0) * 70.0;

      // Compute direction vector.
      Vec2D toCaret = Vec2D.subtract(Vec2D(), _caretWorld, _faceOrigin);
      Vec2D.normalize(toCaret, toCaret);
      Vec2D.scale(toCaret, toCaret, projectGaze);

      // Compute the transform that gets us in face "ctrl_face" space.
      Mat2D toFaceTransform = Mat2D();
      if (Mat2D.invert(toFaceTransform, _faceControl.parent.worldTransform)) {
        // Put toCaret in local space, note we're using a direction vector
        // not a translation so transform without translation
        Vec2D.transformMat2(toCaret, toCaret, toFaceTransform);
        // Our final "ctrl_face" position is the original face translation
        // plus this direction vector
        targetTranslation = Vec2D.add(Vec2D(), toCaret, _faceOriginLocal);
      }
    } else {
      targetTranslation = Vec2D.clone(_faceOriginLocal);
    }

    // We could just set _faceControl.translation to targetTranslation, but we
    // want to animate it smoothly to this target so we interpolate towards it
    // by a factor of elapsed time in order to maintain speed regardless of
    // frame rate.
    Vec2D diff =
        Vec2D.subtract(Vec2D(), targetTranslation, _faceControl.translation);

    Vec2D frameTranslation = Vec2D.add(Vec2D(), _faceControl.translation,
        Vec2D.scale(diff, diff, min(1.0, elapsed * 5.0)));
    _faceControl.translation = frameTranslation;

    return true;
  }

  // Fetch references for the `ctrl_face` node and store a copy of its original
  // translation.
  @override
  void initialize(FlutterActorArtboard artboard) {
    super.initialize(artboard);
    _idleAnimation = artboard.getAnimation("idle");
    _faceControl = artboard.getNode("ctrl_face");
    _faceControl ??= artboard.getNode("look");

    _coverEyesIn = ["cover_eyes_in", "hands_up"].firstWhere(
        (String name) => artboard.getAnimation(name) != null,
        orElse: () => null);
    _coverEyesOut = ["cover_eyes_out", "hands_down"].firstWhere(
        (String name) => artboard.getAnimation(name) != null,
        orElse: () => null);

    if (_faceControl != null) {
      artboard.advance(0);
      _faceControl.getWorldTranslation(_faceOrigin);
      Vec2D.copy(_faceOriginLocal, _faceControl.translation);
    }
  }

  // Called by [FlareActor] when the view transform changes. Updates the matrix
  // that transforms Global-Flutter-coordinates into Flare-World-coordinates.
  @override
  void setViewTransform(Mat2D viewTransform) {
    Mat2D.invert(_globalToFlareWorld, viewTransform);
  }

  // Transform the [Offset] into a [Vec2D]. If no caret is provided, lower the
  // [_hasFocus] flag.
  void lookAt(Offset caret) {
    if (caret == null) {
      _hasFocus = false;
      return;
    }
    _caretGlobal[0] = caret.dx;
    _caretGlobal[1] = caret.dy;
    _hasFocus = true;
  }

  bool _isCoveringEyes = false;
  void coverEyes(bool cover) {
    if (_isCoveringEyes == cover) {
      return;
    }
    _isCoveringEyes = cover;
    if (cover) {
      play(_coverEyesIn);
    } else {
      play(_coverEyesOut);
    }
  }

  /// Play the success animation.
  void rejoice() {
    play("success");
  }

  /// Play the failure animation.
  void lament() {
    play("fail");
  }
}
