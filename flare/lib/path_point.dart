import "math/vec2d.dart";
import "dart:collection";
import "binary_reader.dart";
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

	void read(BinaryReader reader)
	{
		reader.readFloat32Array(_translation.values, 2, 0);
	}

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

	void read(BinaryReader reader)
	{
		super.read(reader);
		radius = reader.readFloat32();
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

	void read(BinaryReader reader)
	{
		super.read(reader);
		reader.readFloat32Array(_in.values, 2, 0);
		reader.readFloat32Array(_out.values, 2, 0);
	}
	
	PathPoint transformed(Mat2D transform)
	{
		CubicPathPoint result = super.transformed(transform) as CubicPathPoint;
		Vec2D.transformMat2D(result.inPoint, result.inPoint, transform);
		Vec2D.transformMat2D(result.outPoint, result.outPoint, transform);
		return result;
	}
}