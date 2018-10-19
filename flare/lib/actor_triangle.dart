import "dart:ui" as ui;
import "package:flare/actor.dart";
import "package:flare/actor_node.dart";
import "package:flare/math/vec2d.dart";
import "package:flare/math/mat2d.dart";
import "package:flare/stream_reader.dart";
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
    List<PathPoint> get _points
    {
        List<PathPoint> _trianglePoints = <PathPoint>[];
        _trianglePoints.add(
            new StraightPathPoint.fromTranslation(
                Vec2D.fromValues(-radiusX, -radiusY)
            )
        );
        _trianglePoints.add(
            new StraightPathPoint.fromTranslation(
                Vec2D.fromValues(radiusX, -radiusY)
            )
        );
        _trianglePoints.add(
            new StraightPathPoint.fromTranslation(
                Vec2D.fromValues(radiusX, radiusY)
            )
        );

        return _trianglePoints;
    }

    @override
    updatePath(ui.Path path)
    {
        List<PathPoint> pts = this._points;
        Mat2D xform = this.transform;
        for(PathPoint p in pts)
        {
            p = p.transformed(xform);
        }

        double x = pts[0].translation[0];
        double y = pts[0].translation[1];

        path.moveTo(x, y);
        path.lineTo(radiusX, radiusY);
        path.lineTo(-radiusX, radiusY);
        path.close();
    }

    bool get isClosed => true;
    bool get doesDraw => !this.renderCollapsed;
    double get radiusX => this.width/2;
    double get radiusY => this.height/2;
}