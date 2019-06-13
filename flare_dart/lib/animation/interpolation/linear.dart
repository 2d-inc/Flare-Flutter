import "./interpolator.dart";

class LinearInterpolator extends Interpolator {
  static Interpolator get instance {
    return _instance;
  }

  @override
  double getEasedMix(double mix) {
    return mix;
  }
}

LinearInterpolator _instance = LinearInterpolator();
