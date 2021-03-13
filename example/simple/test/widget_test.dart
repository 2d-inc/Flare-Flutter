import 'package:flare_flutter/flare.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flare_flutter/flare_cache.dart';
import 'package:flare_flutter/flare_controller.dart';
import 'package:flare_flutter/provider/asset_flare.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class TestController extends FlareController {
  double seconds = 0;
  @override
  bool advance(FlutterActorArtboard artboard, double elapsed) {
    seconds += elapsed;
    return seconds < 0.5;
  }

  @override
  void initialize(FlutterActorArtboard artboard) {}

  @override
  void setViewTransform(Mat2D viewTransform) {}
}

void main() {
  late AssetFlare asset;
  setUp(() async {
    FlareCache.doesPrune = false;
    asset = AssetFlare(bundle: rootBundle, name: 'assets/Filip.flr');
    await cachedActor(asset);
  });

  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Counter increments smoke test', (tester) async {
    final controller = TestController();
    final flareWidget = FlareActor.asset(
      asset,
      alignment: Alignment.center,
      fit: BoxFit.contain,
      controller: controller,
      antialias: true,
    );

    await tester.pumpWidget(flareWidget);
    await tester.pump();
    await tester.pump(Duration(milliseconds: 400));

    expect((controller.seconds - 0.4).abs() < 0.0001, true);
  }, timeout: Timeout(Duration(seconds: 10)));
}
