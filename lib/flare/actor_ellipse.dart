import "actor_component.dart";
import "actor.dart";
import "actor_node.dart";
import "math/vec2d.dart";
import "stream_reader.dart";
import "actor_path.dart";
import "path_point.dart";

const double CircleConstant = 0.55;

class ActorEllipse extends ActorProceduralPath
{
    ActorComponent makeInstance(Actor resetActor)
    {
        ActorEllipse instance = new ActorEllipse();
        instance.copyPath(this, resetActor);
        return instance;
    }

    static ActorEllipse read(Actor actor, StreamReader reader, ActorEllipse component)
    {
        if(component == null)
        {
            component = new ActorEllipse();
        }

        ActorNode.read(actor, reader, component);

        component.width = reader.readFloat32("width");
        component.height = reader.readFloat32("height");
        return component;
    }

    @override
    List<PathPoint> get points
    {
        List<PathPoint> _ellipsePathPoints = <PathPoint>[];
        _ellipsePathPoints.add(
            new CubicPathPoint.fromValues(
                Vec2D.fromValues(0.0, -radiusY), 
                Vec2D.fromValues(-radiusX * CircleConstant, -radiusY), 
                Vec2D.fromValues(radiusX * CircleConstant, -radiusY)
            )
        );
        _ellipsePathPoints.add(
            new CubicPathPoint.fromValues(
                Vec2D.fromValues(radiusX, 0.0), 
                Vec2D.fromValues(radiusX, CircleConstant * -radiusY), 
                Vec2D.fromValues(radiusX, CircleConstant * radiusY)
            )
        );
        _ellipsePathPoints.add(
            new CubicPathPoint.fromValues(
                Vec2D.fromValues(0.0, radiusY), 
                Vec2D.fromValues(radiusX * CircleConstant, radiusY), 
                Vec2D.fromValues(-radiusX * CircleConstant, radiusY)
            )
        );
        _ellipsePathPoints.add(
            new CubicPathPoint.fromValues(
                Vec2D.fromValues(-radiusX, 0.0),
                Vec2D.fromValues(-radiusX, radiusY * CircleConstant), 
                Vec2D.fromValues(-radiusX, -radiusY * CircleConstant)
            )
        );

        return _ellipsePathPoints;
    }

    bool get isClosed => true;
    
    bool get doesDraw
    {
        return !this.renderCollapsed;
    }

    double get radiusX => this.width/2;
    double get radiusY => this.height/2;
}