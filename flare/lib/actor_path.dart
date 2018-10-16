import "dart:typed_data";
import "dart:ui" as ui;
import "dart:math";
import "flare.dart";
import "actor_component.dart";
import "actor_node.dart";
import "actor.dart";
import "stream_reader.dart";
import "path_point.dart";
import "./math/vec2d.dart";
import "./math/mat2d.dart";
import "package:flare/math/aabb.dart";

abstract class ActorBasePath extends ActorNode
{
    static const int PathDirty = 1<<3;

    AABB getPathAABB();
    copyPath(ActorBasePath node, Actor resetActor);
    ActorComponent makeInstance(Actor resetActor);
    void updatePath(ui.Path path);
	
    void onPathInvalid()
    {
        (parent as FlutterActorShape).invalidatePath();
    }

    markPathDirty()
    {
        actor.addDirt(this, PathDirty, false);
        this.onPathInvalid();
    }

    bool get isClosed;
    List<PathPoint> get _points;
}

abstract class ActorProceduralPath extends ActorBasePath
{
    double width = 0.0;
    double height = 0.0;
    
    void copyPath(ActorBasePath node, Actor resetActor)
    {
        ActorProceduralPath nodePath = node as ActorProceduralPath;
        copyNode(nodePath, resetActor);
        width = nodePath.width;
        height = nodePath.height;
    }

    @override
    AABB getPathAABB() 
    {
        double minX = double.maxFinite;
        double minY = double.maxFinite;
        double maxX = -double.maxFinite;
        double maxY = -double.maxFinite;

        Mat2D world = worldTransform;

        double radiusX = this.width/2;
        double radiusY = this.height/2;

        List<Vec2D> points = 
        [
            new Vec2D.fromValues(-radiusX, -radiusY),
            new Vec2D.fromValues(radiusX, -radiusY),
            new Vec2D.fromValues(-radiusX, radiusY),
            new Vec2D.fromValues(radiusX, radiusY)
        ];

        for(Vec2D p in points)
        {
            Vec2D wp = Vec2D.transformMat2D(p, p, world);
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
        return AABB.fromValues(minX, minY, maxX, maxY);
    }
}

class ActorPath extends ActorBasePath
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

	static ActorPath read(Actor actor, StreamReader reader, ActorPath component)
	{
		if(component == null)
		{
			component = new ActorPath();
		}

		ActorNode.read(actor, reader, component);

		component._isHidden = !reader.readBool("isVisible");
		component._isClosed = reader.readBool("isClosed");

        reader.openArray("Points");
		int pointCount = reader.readUint16Length();
		component._points = new List<PathPoint>(pointCount);
		for(int i = 0; i < pointCount; i++)
		{
            reader.openObject("Point");
			PathPoint point;
			PointType type = pointTypeLookup[reader.readUint8("pointType")];
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
            reader.closeObject();
			
			component._points[i] = point;
		}
        reader.closeArray();
		return component;
	}

	ActorComponent makeInstance(Actor resetActor)
	{
		ActorPath instanceEvent = new ActorPath();
		instanceEvent.copyPath(this, resetActor);
		return instanceEvent;
	}

	void copyPath(ActorBasePath node, Actor resetActor)
	{
        ActorPath nodePath = node as ActorPath;
		copyNode(nodePath, resetActor);
		_isHidden = nodePath._isHidden;
		_isClosed = nodePath._isClosed;
		
		int pointCount = nodePath._points.length;
		_points = new List<PathPoint>(pointCount);
		for(int i = 0; i < pointCount; i++)
		{
			_points[i] = nodePath._points[i].makeInstance();
		}

		if(nodePath.vertexDeform != null)
		{
			vertexDeform = new Float32List.fromList(vertexDeform);
		}
	}

	AABB getPathOBB()
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

		return new AABB.fromValues(minX, minY, maxX, maxY);
	}

	AABB getPathAABB()
	{
		double minX = double.maxFinite;
		double minY = double.maxFinite;
		double maxX = -double.maxFinite;
		double maxY = -double.maxFinite;

		AABB obb = getPathOBB();

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

		return new AABB.fromValues(minX, minY, maxX, maxY);
	}

    void updatePath(ui.Path path)
	{
		if(points == null || points.length == 0)
		{
			return;
		}
		Mat2D xform = this.transform;

		List<PathPoint> renderPoints = new List<PathPoint>();
		int pl = points.length;
		
		const double arcConstant = 0.55;
		const double iarcConstant = 1.0-arcConstant;
		PathPoint previous = isClosed ? points[pl-1].transformed(xform) : null;
		for(int i = 0; i < pl; i++)
		{
			PathPoint point = points[i].transformed(xform);
			switch(point.pointType)
			{
				case PointType.Straight:
				{
					StraightPathPoint straightPoint = point as StraightPathPoint;
					double radius = straightPoint.radius;
					if(radius > 0)
					{
						if(!isClosed && (i == 0 || i == pl-1))
						{
							renderPoints.add(point);
							previous = point;
						}
						else
						{
							PathPoint next = points[(i+1)%pl].transformed(xform);
							Vec2D prevPoint = previous is CubicPathPoint ? previous.outPoint : previous.translation;
							Vec2D nextPoint = next is CubicPathPoint ? next.inPoint : next.translation;
							Vec2D pos = point.translation;

							Vec2D toPrev = Vec2D.subtract(new Vec2D(), prevPoint, pos);
							double toPrevLength = Vec2D.length(toPrev);
							toPrev[0] /= toPrevLength;
							toPrev[1] /= toPrevLength;

							Vec2D toNext = Vec2D.subtract(new Vec2D(), nextPoint, pos);
							double toNextLength = Vec2D.length(toNext);
							toNext[0] /= toNextLength;
							toNext[1] /= toNextLength;

							double renderRadius = min(toPrevLength, min(toNextLength, radius));

							Vec2D translation = Vec2D.scaleAndAdd(new Vec2D(), pos, toPrev, renderRadius);
							renderPoints.add(new CubicPathPoint.fromValues(translation, translation, Vec2D.scaleAndAdd(new Vec2D(), pos, toPrev, iarcConstant*renderRadius)));
							translation = Vec2D.scaleAndAdd(new Vec2D(), pos, toNext, renderRadius);
							previous = new CubicPathPoint.fromValues(translation, Vec2D.scaleAndAdd(new Vec2D(), pos, toNext, iarcConstant*renderRadius), translation);
							renderPoints.add(previous);
						}
					}
					else
					{
						renderPoints.add(point);
						previous = point;
					}
					break;
				}
				default:
					renderPoints.add(point);
					previous = point;
					break;
			}
		}

		PathPoint firstPoint = renderPoints[0];
		path.moveTo(firstPoint.translation[0], firstPoint.translation[1]);
		for(int i = 0, l = isClosed ? renderPoints.length : renderPoints.length-1, pl = renderPoints.length; i < l; i++)
		{
			PathPoint point = renderPoints[i];
			PathPoint nextPoint = renderPoints[(i+1)%pl];
			Vec2D cin = nextPoint is CubicPathPoint ? nextPoint.inPoint : null;
            Vec2D cout = point is CubicPathPoint ? point.outPoint : null;
			if(cin == null && cout == null)
			{
				path.lineTo(nextPoint.translation[0], nextPoint.translation[1]);	
			}
			else
			{
				if(cout == null)
				{
					cout = point.translation;
				}
				if(cin == null)
				{
					cin = nextPoint.translation;
				}

				path.cubicTo(
					cout[0], cout[1],

					cin[0], cin[1],

					nextPoint.translation[0], nextPoint.translation[1]);
			}
		}

		if(isClosed)
		{
			path.close();
		}
	}
}
