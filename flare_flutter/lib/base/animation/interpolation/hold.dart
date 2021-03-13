import 'package:flare_flutter/base/animation/interpolation/interpolator.dart';

class HoldInterpolator extends Interpolator {
  static Interpolator get instance {
    return _instance;
  }

  @override
  double getEasedMix(double mix) {
    return 0.0;
  }
}

HoldInterpolator _instance = HoldInterpolator();
