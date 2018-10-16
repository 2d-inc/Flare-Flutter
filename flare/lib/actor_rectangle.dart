import "dart:ui" as ui;
import "package:flare/actor.dart";
import "package:flare/actor_node.dart";
import "package:flare/math/vec2d.dart";
import "package:flare/math/mat2d.dart";
import "package:flare/stream_reader.dart";
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
    List<PathPoint> get _points
    {
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

    @override
    updatePath(ui.Path path)
    {
        Mat2D xform = this.transform;
        Vec2D topLeft = Vec2D.fromValues(-halfWidth, halfHeight);
        Vec2D.transformMat2D(topLeft, topLeft, xform);
        
        Vec2D bottomRight = Vec2D.fromValues(halfWidth, -halfHeight);
        Vec2D.transformMat2D(bottomRight, bottomRight, xform);
        
        path.moveTo(x, y);

        path.addRRect(
            new ui.RRect.fromLTRBR(
                topLeft[0],
                topLeft[1],
                bottomRight[0],
                bottomRight[1],
                ui.Radius.circular(_radius)
            )
        );
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
        return !this.renderCollapsed;
    }

    double get halfWidth => this.width/2;
    double get halfHeight => this.height/2;

    double get radius => _radius;
}