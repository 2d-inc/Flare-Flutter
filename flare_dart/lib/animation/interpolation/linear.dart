import "./interpolator.dart";

class LinearInterpolator extends Interpolator {
  static get instance {
    return _instance;
  }

  double getEasedMix(double mix) {
    return mix;
  }
}

LinearInterpolator _instance = LinearInterpolator();
