import "dart:ui" as ui;
import "dart:math";
import "package:flare/actor.dart";
import "package:flare/actor_node.dart";
import "package:flare/math/vec2d.dart";
import "package:flare/math/mat2d.dart";
import "package:flare/stream_reader.dart";
import "actor_path.dart";
import "path_point.dart";

class ActorPolygon extends ActorProceduralPath
{
    int _sides = 5;

    ActorPolygon makeInstance(Actor resetActor)
    {
        ActorPolygon instance = new ActorPolygon();
        instance.copyPath(this, resetActor);
        instance._sides = this._sides;
        return instance;
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
        component._sides = reader.readUint32("sides");
        return component;
    }

    @override
    List<PathPoint> get _points
    {
        List<PathPoint> _polygonPoints = <PathPoint>[];
        double angle = -pi/2.0;
        double inc = (pi*2.0)/_sides;

        for(int i=0; i < _sides; i++)
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

    @override
    updatePath(ui.Path path)
    {
        Mat2D xform = this.transform;
        List<PathPoint> pts = this._points;
        for(PathPoint p in pts)
        {
            p = p.transformed(xform);
        }

        path.moveTo(0.0, -radiusY);
        double angle = -pi/2.0;
        double inc = (pi*2.0)/_sides;

        for(int i = 0; i < _sides; i++)
        {
            path.lineTo(cos(angle)*radiusX, sin(angle)*radiusY);
            angle += inc;
        }

        path.close();
    }

    bool get isClosed => true;
    bool get doesDraw => !this.renderCollapsed;
    double get radiusX => this.width/2;
    double get radiusY => this.height/2;
}