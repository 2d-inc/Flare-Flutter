import "../../stream_reader.dart";
import "./interpolator.dart";
import "cubic_ease.dart";

class CubicInterpolator extends Interpolator {
  late CubicEase _cubic;
  @override
  double getEasedMix(double mix) {
    return _cubic.ease(mix);
  }

  bool read(StreamReader reader) {
    _cubic = CubicEase.make(
        reader.readFloat32("cubicX1"),
        reader.readFloat32("cubicY1"),
        reader.readFloat32("cubicX2"),
        reader.readFloat32("cubicY2"));
    return true;
  }
}
