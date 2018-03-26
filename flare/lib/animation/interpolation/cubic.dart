import "./interpolator.dart";
import "../../binary_reader.dart";
import "package:flutter/animation.dart";


class CubicInterpolator extends Interpolator
{	
	Cubic _cubic;
	double getEasedMix(double mix)
	{
		return _cubic.transform(mix);
	}

	bool read(BinaryReader reader)
	{
		_cubic = new Cubic(reader.readFloat32(), reader.readFloat32(), reader.readFloat32(), reader.readFloat32());
		return true;
	}
}