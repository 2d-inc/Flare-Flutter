import "actor.dart";
import "actor_node.dart";
import "math/vec2d.dart";
import "stream_reader.dart";
import "actor_path.dart";
import "path_point.dart";

class ActorTriangle extends ActorProceduralPath
{
    ActorTriangle makeInstance(Actor resetActor)
    {
        ActorTriangle instance = new ActorTriangle();
        instance.copyPath(this, resetActor);
        return instance;
    }

    static ActorTriangle read(Actor actor, StreamReader reader, ActorTriangle component)
    {
        if(component == null)
        {
            component = new ActorTriangle();
        }

        ActorNode.read(actor, reader, component);

        component.width = reader.readFloat32("width");
        component.height = reader.readFloat32("height");
        return component;
    }

    @override
    List<PathPoint> get points
    {
        List<PathPoint> _trianglePoints = <PathPoint>[];
        _trianglePoints.add(
            new StraightPathPoint.fromTranslation(
                Vec2D.fromValues(0.0, -radiusY)
            )
        );
        _trianglePoints.add(
            new StraightPathPoint.fromTranslation(
                Vec2D.fromValues(radiusX, radiusY)
            )
        );
        _trianglePoints.add(
            new StraightPathPoint.fromTranslation(
                Vec2D.fromValues(-radiusX, radiusY)
            )
        );

        return _trianglePoints;
    }

    bool get isClosed => true;
    bool get doesDraw => !this.renderCollapsed;
    double get radiusX => this.width/2;
    double get radiusY => this.height/2;
}