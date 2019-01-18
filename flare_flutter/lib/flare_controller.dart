import 'flare.dart';
import 'package:flare_dart/math/mat2d.dart';

///
/// [FlareController] is a general-purpose interface for customizing
/// the behavior of a Flare animation at runtime.
///
/// It provides three methods
/// - [initialize()] is called at initialization time.
/// - [setViewTransform()] and [advance()] are called every frame.
///
/// [FlareController]s can be attached to [FlareActor] widgets
/// as an optional parameter.
/// e.g.:
/// ```
/// FlareActor(
///    "flare_file.flr",
///    controller: _myCustomController
/// )
/// ```
///
/// A basic implementation can be found in [FlareControls].

abstract class FlareController {
  /// Useful to fetch references to animation components that will be affected
  /// by this controller.
  void initialize(FlutterActorArtboard artboard);

  /// Relays the information regarding the global Flutter [viewTransform] matrix
  /// of the [FlareActor] this controller is attached to.
  void setViewTransform(Mat2D viewTransform);

  /// Advances the animation of the current [artboard] by [elapsed].
  bool advance(FlutterActorArtboard artboard, double elapsed);
}
