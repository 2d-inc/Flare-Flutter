import "dart:math";
import "actor.dart";
import "actor_node.dart";
import "math/vec2d.dart";
import "stream_reader.dart";
import "actor_path.dart";
import "path_point.dart";
import "actor_component.dart";

class ActorPolygon extends ActorProceduralPath
{
    int sides = 5;

    ActorComponent makeInstance(Actor resetActor)
    {
        ActorPolygon instance = new ActorPolygon();
        instance.copyPolygon(this, resetActor);
        return instance;
    }

    void copyPolygon(ActorPolygon node, Actor resetActor)
    {
		copyPath(node, resetActor);
        sides = node.sides;
    }

    static ActorPolygon read(Actor actor, StreamReader reader, ActorPolygon component)
    {
        if(component == null)
        {
            component = new ActorPolygon();
        }

        ActorNode.read(actor, reader, component);

        component.width = reader.readFloat32("width");
        component.height = reader.readFloat32("height");
        component.sides = reader.readUint32("sides");
        return component;
    }

    @override
    List<PathPoint> get points
    {
        List<PathPoint> _polygonPoints = <PathPoint>[];
        double angle = -pi/2.0;
        double inc = (pi*2.0)/sides;

        for(int i=0; i < sides; i++)
        {
            _polygonPoints.add(
                new StraightPathPoint.fromTranslation(
                    Vec2D.fromValues(cos(angle)*radiusX, sin(angle)*radiusY)
                )
            );
            angle += inc;
        }
        
        return _polygonPoints;
    }

    bool get isClosed => true;
    bool get doesDraw => !this.renderCollapsed;
    double get radiusX => this.width/2;
    double get radiusY => this.height/2;
}