import "actor_component.dart";
import "actor_node.dart";
import "actor.dart";
import "binary_reader.dart";
import "path_point.dart";
import "./math/vec2d.dart";
import "./math/mat2d.dart";
import "dart:typed_data";

class ActorPath extends ActorNode
{
	bool _isHidden;
	bool _isClosed;
	List<PathPoint> _points;
	Float32List vertexDeform;

	static const int VertexDeformDirty = 1<<1;

	List<PathPoint> get points
	{
		return _points;
	}

	bool get isClosed
	{
		return _isClosed;
	}

	void markVertexDeformDirty()
	{
		if(actor == null)
		{
			return;
		}
		actor.addDirt(this, VertexDeformDirty, false);
	}

	void onPathInvalid(){}

	void update(int dirt)
	{
		if(vertexDeform != null && (dirt & VertexDeformDirty) == VertexDeformDirty)
		{
			int readIdx = 0;
			for(PathPoint point in _points)
			{
				point.translation[0] = vertexDeform[readIdx++];
				point.translation[1] = vertexDeform[readIdx++];
				switch(point.pointType)
				{
					case PointType.Straight:
						(point as StraightPathPoint).radius = vertexDeform[readIdx++];
						break;
					
					default:
						CubicPathPoint cubicPoint = point as CubicPathPoint;
						cubicPoint.inPoint[0] = vertexDeform[readIdx++];
						cubicPoint.inPoint[1] = vertexDeform[readIdx++];
						cubicPoint.outPoint[0] = vertexDeform[readIdx++];
						cubicPoint.outPoint[1] = vertexDeform[readIdx++];
						break;
				}
			}
		}
		if(dirt != 0)
		{
			onPathInvalid();
		}
		super.update(dirt);
	}

	static ActorPath read(Actor actor, BinaryReader reader, ActorPath component)
	{
		if(component == null)
		{
			component = new ActorPath();
		}

		ActorNode.read(actor, reader, component);

		component._isHidden = reader.readUint8() == 0;
		component._isClosed = reader.readUint8() == 1;

		int pointCount = reader.readUint16();
		component._points = new List<PathPoint>(pointCount);
		for(int i = 0; i < pointCount; i++)
		{
			PathPoint point;
			PointType type = pointTypeLookup[reader.readUint8()];
			switch(type)
			{
				case PointType.Straight:
				{
					point = new StraightPathPoint();
					break;
				}
				default:
				{
					point = new CubicPathPoint(type);
					break;
				}
			}
			if(point == null)
			{
				throw new UnsupportedError("Invalid point type " + type.toString());
			}
			else
			{
				point.read(reader);
			}
			
			component._points[i] = point;
		}
		return component;
	}

	ActorComponent makeInstance(Actor resetActor)
	{
		ActorPath instanceEvent = new ActorPath();
		instanceEvent.copyPath(this, resetActor);
		return instanceEvent;
	}

	void copyPath(ActorPath node, Actor resetActor)
	{
		copyNode(node, resetActor);
		_isHidden = node._isHidden;
		_isClosed = node._isClosed;
		
		int pointCount = node._points.length;
		_points = new List<PathPoint>(pointCount);
		for(int i = 0; i < pointCount; i++)
		{
			_points[i] = node._points[i].makeInstance();
		}

		if(node.vertexDeform != null)
		{
			vertexDeform = new Float32List.fromList(vertexDeform);
		}
	}

	Float32List getPathOBB()
	{
		double minX = double.maxFinite;
		double minY = double.maxFinite;
		double maxX = -double.maxFinite;
		double maxY = -double.maxFinite;

		for(PathPoint point in _points)
		{
			Vec2D t = point.translation;
			double x = t[0];
			double y = t[1];
			if(x < minX)
			{
				minX = x;
			}
			if(y < minY)
			{
				minY = y;
			}
			if(x > maxX)
			{
				maxX = x;
			}
			if(y > maxY)
			{
				maxY = y;
			}

			if(point is CubicPathPoint)
			{
				Vec2D t = point.inPoint;
				x = t[0];
				y = t[1];
				if(x < minX)
				{
					minX = x;
				}
				if(y < minY)
				{
					minY = y;
				}
				if(x > maxX)
				{
					maxX = x;
				}
				if(y > maxY)
				{
					maxY = y;
				}

				t = point.outPoint;
				x = t[0];
				y = t[1];
				if(x < minX)
				{
					minX = x;
				}
				if(y < minY)
				{
					minY = y;
				}
				if(x > maxX)
				{
					maxX = x;
				}
				if(y > maxY)
				{
					maxY = y;
				}
			}
		}

		return new Float32List.fromList([minX, minY, maxX, maxY]);
	}

	Float32List getPathAABB()
	{
		double minX = double.maxFinite;
		double minY = double.maxFinite;
		double maxX = -double.maxFinite;
		double maxY = -double.maxFinite;

		Float32List obb = getPathOBB();

		List<Vec2D> points = [
			new Vec2D.fromValues(obb[0], obb[1]),
			new Vec2D.fromValues(obb[2], obb[1]),
			new Vec2D.fromValues(obb[2], obb[3]),
			new Vec2D.fromValues(obb[0], obb[3])
		];
		
		Mat2D transform = this.transform;
		for(int i = 0; i < points.length; i++)
		{
			Vec2D pt = points[i];
			Vec2D wp = Vec2D.transformMat2D(pt, pt, transform);
			if(wp[0] < minX)
			{
				minX = wp[0];
			}
			if(wp[1] < minY)
			{
				minY = wp[1];
			}

			if(wp[0] > maxX)
			{
				maxX = wp[0];
			}
			if(wp[1] > maxY)
			{
				maxY = wp[1];
			}
		}

		return new Float32List.fromList([minX, minY, maxX, maxY]);
	}
}
