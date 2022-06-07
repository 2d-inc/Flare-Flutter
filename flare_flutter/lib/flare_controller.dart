import 'package:flutter/foundation.dart';

import 'flare.dart';

///
/// [FlareController] is a general-purpose interface for customizing
/// the behavior of a Flare animation at runtime.
///
///
/// [FlareController]s should be attached to [FlareActor] widgets:
/// ```
/// FlareActor(
///    "flare_file.flr",
///    controller: _myCustomController
/// )
/// ```
///
/// [FlareController]s can implement three methods:
/// - [initialize()] is called when the [FlareActor] is first created.
/// - [setViewTransform()] and [advance()] are called every time the
/// [FlareActor] widget is repainted.
///
/// A basic implementation can be found in [FlareControls].

abstract class FlareController {
  ValueNotifier<bool> isActive = ValueNotifier<bool>(true);

  /// Advances the animation of the current [artboard] by [elapsed].
  bool advance(FlutterActorArtboard artboard, double elapsed);

  /// Useful to fetch references to animation components that will be affected
  /// by this controller.
  void initialize(FlutterActorArtboard artboard);

  /// Relays the information regarding the global Flutter [viewTransform] matrix
  /// of the [FlareActor] this controller is attached to.
  void setViewTransform(Mat2D viewTransform);
}
