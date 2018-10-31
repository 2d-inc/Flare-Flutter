import "./interpolator.dart";
import "../../stream_reader.dart";
import "package:flutter/animation.dart";


class CubicInterpolator extends Interpolator
{	
	Cubic _cubic;
	double getEasedMix(double mix)
	{
		return _cubic.transform(mix);
	}

	bool read(StreamReader reader)
	{
		_cubic = new Cubic(
            reader.readFloat32("cubicX1"),
            reader.readFloat32("cubicY1"),
            reader.readFloat32("cubicX2"), 
            reader.readFloat32("cubicY2")
        );
		return true;
	}
}