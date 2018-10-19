import 'dart:math';
import "dart:ui" as ui;
import "package:flare/actor.dart";
import "package:flare/actor_node.dart";
import "package:flare/math/vec2d.dart";
import "package:flare/math/mat2d.dart";
import "package:flare/math/aabb.dart";
import "package:flare/stream_reader.dart";
import "actor_path.dart";
import "path_point.dart";

class ActorStar extends ActorProceduralPath
{
    int _numPoints = 5;
    double _innerRadius = 0.0;

    ActorStar makeInstance(Actor resetActor)
    {
        ActorStar instance = new ActorStar();
        instance.copyPath(this, resetActor);
        instance._numPoints = this._numPoints;
        instance._innerRadius = this._innerRadius;
        return instance;
    }

    static ActorStar read(Actor actor, StreamReader reader, ActorStar component)
    {
        if(component == null)
        {
            component = new ActorStar();
        }

        ActorNode.read(actor, reader, component);

        component.width = reader.readFloat32("width");
        component.height = reader.readFloat32("height");
        component._numPoints = reader.readUint32("points");
        component._innerRadius = reader.readFloat32("innerRadius");
        print("JUST READ A STAR: ${component._numPoints} points and ${component._innerRadius} radius");
        return component;
    }

    @override
    List<PathPoint> get _points
    {
        List<PathPoint> _starPoints = <PathPoint>[];

        double angle = pi/2.0;
        double inc = (pi*2.0)/sides;
        Vec2D sx = Vec2D.fromValues(radiusX, radiusX*innerRadius);
        Vec2D sy = Vec2D.fromValues(radiusY, radiusY*innerRadius);

        for(int i = 0; i < sides; i++)
        {
            _starPoints.add(
                new StraightPathPoint.fromTranslation(
                    Vec2D.fromValues(
                        cos(angle)*sx[i%2], 
                        sin(angle)*sy[i%2]
                    )
                )
            );
            angle += inc;
        }
        return _starPoints;
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

        path.moveTo(0.0, -radiusY);
        double angle = -pi/2.0;
        double inc = (pi*2.0)/sides;
        Vec2D sx = Vec2D.fromValues(radiusX, radiusX*innerRadius);
        Vec2D sy = Vec2D.fromValues(radiusY, radiusY*innerRadius);
        
        for(int i = 0; i < sides; i++)
        {
            path.lineTo(cos(angle)*sx[i%2], sin(angle)*sy[i%2]);
            angle += inc;
        }
        path.close();
    }

    @override
    AABB getPathAABB() 
    {
        double minX = double.maxFinite;
        double minY = double.maxFinite;
        double maxX = -double.maxFinite;
        double maxY = -double.maxFinite;

        List<Vec2D> pts = [];
        for(PathPoint p in _points)
        {
            pts.add(p.translation);
        }

        Mat2D world = worldTransform;

        for(Vec2D p in pts)
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

    bool get isClosed => true;
    bool get doesDraw => !this.renderCollapsed;
    double get radiusX => this.width/2;
    double get radiusY => this.height/2;
    int get numPoints => _numPoints;
    int get sides => _numPoints*2;
    double get innerRadius => _innerRadius;

    set sides(int val)
    {
        if(_numPoints != val)
        {
            _numPoints = val;
            markPathDirty();
        }
    }

    set innerRadius(double val)
    {
        if(val != _innerRadius)
        {
            _innerRadius = val;
            markPathDirty();
        }
    }

}