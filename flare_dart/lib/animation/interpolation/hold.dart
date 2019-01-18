import "./interpolator.dart";

class HoldInterpolator extends Interpolator {
  static get instance {
    return _instance;
  }

  double getEasedMix(double mix) {
    return 0.0;
  }
}

HoldInterpolator _instance = HoldInterpolator();
