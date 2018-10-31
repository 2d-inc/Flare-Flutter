import "actor.dart";
import "actor_node.dart";
import "math/vec2d.dart";
import "stream_reader.dart";
import "actor_path.dart";
import "path_point.dart";

const double CircleConstant = 0.55;

class ActorRectangle extends ActorProceduralPath
{
    double _radius = 0.0;

    ActorRectangle makeInstance(Actor resetActor)
    {
        ActorRectangle instance = new ActorRectangle();
        instance.copyPath(this, resetActor);
        instance._radius = this._radius;
        return instance;
    }

    static ActorRectangle read(Actor actor, StreamReader reader, ActorRectangle component)
    {
        if(component == null)
        {
            component = new ActorRectangle();
        }

        ActorNode.read(actor, reader, component);

        component.width = reader.readFloat32("width");
        component.height = reader.readFloat32("height");
        component._radius = reader.readFloat32("cornerRadius");
        return component;
    }

    @override
    List<PathPoint> get points
    {
		double halfWidth = width/2.0;
		double halfHeight = height/2.0;
        List<PathPoint> _rectanglePathPoints = <PathPoint>[];
        _rectanglePathPoints.add(
            new StraightPathPoint.fromValues(
                Vec2D.fromValues(-halfWidth, -halfHeight),
                _radius
            )
        );
        _rectanglePathPoints.add(
            new StraightPathPoint.fromValues(
                Vec2D.fromValues(halfWidth, -halfHeight),
                _radius
            )
        );
        _rectanglePathPoints.add(
            new StraightPathPoint.fromValues(
                Vec2D.fromValues(halfWidth, halfHeight),
                _radius
            )
        );
        _rectanglePathPoints.add(
            new StraightPathPoint.fromValues(
                Vec2D.fromValues(-halfWidth, halfHeight),
                _radius
            )
        );

        return _rectanglePathPoints;
    }

    set radius(double rd)
    {
        if(rd != _radius)
        {
            _radius = rd;
            markPathDirty();
        }
    }

    bool get isClosed => true;
    
    bool get doesDraw
    {
        return !renderCollapsed;
    }

    double get radius => _radius;
}