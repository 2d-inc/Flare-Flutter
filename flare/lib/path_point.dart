import "./math/vec2d.dart";
import "dart:collection";
import "binary_reader.dart";

enum PointType
{
	Straight,
	Mirror,
	Disconnected,
	Asymmetric
}

HashMap<int,PointType> pointTypeLookup = new HashMap<int,PointType>.fromIterables([0,1,2], [PointType.Straight, PointType.Mirror, PointType.Disconnected, PointType.Asymmetric]);

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
}

class StraightPathPoint extends PathPoint
{
	double _radius = 0.0;

	double get radius
	{
		return _radius;
	}

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
		_radius = from._radius;
	}

	void read(BinaryReader reader)
	{
		super.read(reader);
		_radius = reader.readFloat32();
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
}