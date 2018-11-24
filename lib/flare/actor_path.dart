import "dart:typed_data";
import "actor_shape.dart";
import "actor_component.dart";
import "actor_node.dart";
import "actor_skin.dart";
import "actor_skinnable.dart";
import "actor_artboard.dart";
import "stream_reader.dart";
import "path_point.dart";
import "math/vec2d.dart";
import "math/mat2d.dart";
import "math/aabb.dart";

abstract class ActorBasePath
{
    //bool get isClosed;
    List<PathPoint> get points;
	ActorNode get parent;
	void invalidatePath();
	bool get isPathInWorldSpace => false;
	Mat2D get pathTransform;
	Mat2D get transform;
	List<ActorClip> get allClips;
	List<PathPoint> get deformedPoints => points;

    AABB getPathAABB()
    {
        double minX = double.maxFinite;
        double minY = double.maxFinite;
        double maxX = -double.maxFinite;
        double maxY = -double.maxFinite;

        AABB obb = getPathOBB();

        List<Vec2D> pts = [
            new Vec2D.fromValues(obb[0], obb[1]),
			new Vec2D.fromValues(obb[2], obb[1]),
			new Vec2D.fromValues(obb[2], obb[3]),
			new Vec2D.fromValues(obb[0], obb[3])
        ];

        Mat2D localTransform;
		if(isPathInWorldSpace)
		{
			//  convert the path coordinates into local parent space.
			localTransform = new Mat2D();
			Mat2D.invert(localTransform, parent.worldTransform);
		}
		else
		{
			localTransform = transform;
		}

        for(Vec2D p in pts)
        {
            Vec2D wp = Vec2D.transformMat2D(p, p, localTransform);
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

	markPathDirty()
	{
		invalidatePath();
		if(parent is ActorShape)
		{
			parent.invalidateShape();
		}
	}

    AABB getPathOBB()
	{
		double minX = double.maxFinite;
		double minY = double.maxFinite;
		double maxX = -double.maxFinite;
		double maxY = -double.maxFinite;

		List<PathPoint> renderPoints = points;
		for(PathPoint point in renderPoints)
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
}

abstract class ActorProceduralPath extends ActorNode with ActorBasePath
{
    double _width;
    double _height;

	double get width => _width;
	double get height => _height;

	@override
	Mat2D get pathTransform => worldTransform;

	set width(double w)
	{
		if(w != _width)
		{
			_width = w;
            markPathDirty();
		}
	}

	set height(double w)
	{
		if(w != _height)
		{
			_height = w;
            markPathDirty();
		}
	}
    
    void copyPath(ActorBasePath node, ActorArtboard resetArtboard)
    {
        ActorProceduralPath nodePath = node as ActorProceduralPath;
        copyNode(nodePath, resetArtboard);
        _width = nodePath.width;
        _height = nodePath.height;
    }
}

class ActorPath extends ActorSkinnable with ActorBasePath
{
	bool _isHidden;
	bool _isClosed;
    List<PathPoint> _points;
	Float32List vertexDeform;
	ActorSkin skin;

	@override
	bool get isPathInWorldSpace => isConnectedToBones;

	@override
	void invalidatePath()
	{
		// Up to the implementation.
	}


	@override
	Mat2D get pathTransform => isConnectedToBones ? null : worldTransform;

	static const int VertexDeformDirty = 1<<1;

	@override
	List<PathPoint> get points => _points;
	
	@override
	List<PathPoint> get deformedPoints
	{
		if(!isConnectedToBones || skin == null)
		{
			return _points;
		}
		
		Float32List boneMatrices = skin.boneMatrices;
		List<PathPoint> deformed = <PathPoint>[];
		for(PathPoint point in _points)
		{
			deformed.add(point.skin(worldTransform, boneMatrices));
		}
		return deformed;
	}

	bool get isClosed
	{
		return _isClosed;
	}

	void markVertexDeformDirty()
	{
		if(artboard == null)
		{
			return;
		}
		artboard.addDirt(this, VertexDeformDirty, false);
	}

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
		markPathDirty();

		super.update(dirt);
	}

	static ActorPath read(ActorArtboard artboard, StreamReader reader, ActorPath component)
	{
		if(component == null)
		{
			component = new ActorPath();
		}

		ActorSkinnable.read(artboard, reader, component);

		component._isHidden = !reader.readBool("isVisible");
		component._isClosed = reader.readBool("isClosed");

        reader.openArray("points");
		int pointCount = reader.readUint16Length();
		component._points = new List<PathPoint>(pointCount);
		for(int i = 0; i < pointCount; i++)
		{
            reader.openObject("point");
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
				point.read(reader, component.isConnectedToBones);
			}
            reader.closeObject();
			
			component._points[i] = point;
		}
        reader.closeArray();
		return component;
	}

	ActorComponent makeInstance(ActorArtboard resetArtboard)
	{
		ActorPath instanceEvent = new ActorPath();
		instanceEvent.copyPath(this, resetArtboard);
		return instanceEvent;
	}

	void copyPath(ActorBasePath node, ActorArtboard resetArtboard)
	{
        ActorPath nodePath = node as ActorPath;
		copySkinnable(nodePath, resetArtboard);
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
			vertexDeform = new Float32List.fromList(nodePath.vertexDeform);
		}
	}
}
