import "dart:ui" as ui;
import "package:flare/actor.dart";
import "package:flare/actor_node.dart";
import "package:flare/math/vec2d.dart";
import "package:flare/math/mat2d.dart";
import "package:flare/stream_reader.dart";
import "actor_path.dart";
import "path_point.dart";

const double CircleConstant = 0.55;

class ActorEllipse extends ActorProceduralPath
{
    ActorEllipse makeInstance(Actor resetActor)
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
    List<PathPoint> get _points
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

    @override
    updatePath(ui.Path path)
    {
        List<PathPoint> points = this._points;
        Mat2D xform = this.transform;

        for(CubicPathPoint p in points)
        {
            p = p.transformed(xform);
        }

        double x = points[0].translation[0],
            y = points[0].translation[1];
        path.moveTo(x, y);
        
        for(int i = 0; i < points.length; i++)
        {
            CubicPathPoint point = points[i];
            CubicPathPoint nextPoint = points[(i+1)%points.length];
            Vec2D t = nextPoint.translation;
            Vec2D cin = nextPoint.inPoint;
            Vec2D cout = point.outPoint;
            path.cubicTo(
                cout[0], cout[1],
                cin[0], cin[1],
                t[0], t[1]
            );
        }
        path.close();
    }

    bool get isClosed => true;
    
    bool get doesDraw
    {
        return !this.renderCollapsed;
    }

    double get radiusX => this.width/2;
    double get radiusY => this.height/2;
}