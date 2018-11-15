import "dart:typed_data";
import "math/vec2d.dart";
import "dart:collection";
import "stream_reader.dart";
import "math/mat2d.dart";

enum PointType
{
	Straight,
	Mirror,
	Disconnected,
	Asymmetric
}

HashMap<int,PointType> pointTypeLookup = new HashMap<int,PointType>.fromIterables([0,1,2,3], [PointType.Straight, PointType.Mirror, PointType.Disconnected, PointType.Asymmetric]);

abstract class PathPoint
{
	PointType _type;
	Vec2D _translation = new Vec2D();
	Float32List _weights;

	PathPoint(PointType type)
	{
		_type = type;
	}

	PointType get pointType
	{
		return _type;
	}

	Vec2D get translation
	{
		return _translation;
	}

	PathPoint makeInstance();

	copy(PathPoint from)
	{
		this._type = from._type;
		Vec2D.copy(_translation, from._translation);
	}

	void read(StreamReader reader, bool isConnectedToBones)
	{
		reader.readFloat32ArrayOffset(_translation.values, 2, 0, "translation");
		readPoint(reader, isConnectedToBones);
		if(_weights != null)
		{
			reader.readFloat32Array(_weights, "weights");
		}
	}

	void readPoint(StreamReader reader, bool isConnectedToBones);

	PathPoint transformed(Mat2D transform)
	{
		PathPoint result = makeInstance();
		Vec2D.transformMat2D(result.translation, result.translation, transform);
		return result;
	}
}

class StraightPathPoint extends PathPoint
{
	double radius = 0.0;

	StraightPathPoint() : super(PointType.Straight);
	
    StraightPathPoint.fromTranslation(Vec2D translation) : super(PointType.Straight)
    {
        this._translation = translation;
    }

	StraightPathPoint.fromValues(Vec2D translation, double r) : super(PointType.Straight)
    {
        _translation = translation;
        radius = r;
    }
	
	PathPoint makeInstance()
	{
		StraightPathPoint node = new StraightPathPoint();
		node.copyStraight(this);
		return node;	
	}

	copyStraight(StraightPathPoint from)
	{
		super.copy(from);
		radius = from.radius;
	}

	void readPoint(StreamReader reader, bool isConnectedToBones)
	{
		radius = reader.readFloat32("radius");
		if(isConnectedToBones)
		{
			_weights = new Float32List(8);
		}
	}
}

class CubicPathPoint extends PathPoint
{
	Vec2D _in = new Vec2D();
	Vec2D _out = new Vec2D();

	CubicPathPoint(PointType type) : super(type);

	Vec2D get inPoint
	{
		return _in;
	}
	
	Vec2D get outPoint
	{
		return _out;
	}

	CubicPathPoint.fromValues(Vec2D translation, Vec2D inPoint, Vec2D outPoint) : super(PointType.Disconnected)
	{
		_translation = translation;
		_in = inPoint;
		_out = outPoint;
	}
	
	PathPoint makeInstance()
	{
		CubicPathPoint node = new CubicPathPoint(_type);
		node.copyCubic(this);
		return node;	
	}

	copyCubic(from)
	{
		super.copy(from);
		Vec2D.copy(_in, from._in);
		Vec2D.copy(_out, from._out);
	}

	void readPoint(StreamReader reader, bool isConnectedToBones)
	{
		reader.readFloat32ArrayOffset(_in.values, 2, 0, "in");
		reader.readFloat32ArrayOffset(_out.values, 2, 0, "out");
		if(isConnectedToBones)
		{
			_weights = new Float32List(24);
		}
	}
	
	PathPoint transformed(Mat2D transform)
	{
		CubicPathPoint result = super.transformed(transform) as CubicPathPoint;
		Vec2D.transformMat2D(result.inPoint, result.inPoint, transform);
		Vec2D.transformMat2D(result.outPoint, result.outPoint, transform);
		return result;
	}
}