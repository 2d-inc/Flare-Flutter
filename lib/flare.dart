library flare;

import "dart:async";
import "dart:typed_data";
import "package:flutter/material.dart";

import "flare/actor_component.dart";

import "flare/actor.dart";
import "flare/actor_artboard.dart";
import "flare/actor_shape.dart";
import "flare/actor_path.dart";
import "flare/actor_ellipse.dart";
import "flare/actor_polygon.dart";
import "flare/actor_rectangle.dart";
import "flare/actor_star.dart";
import "flare/actor_triangle.dart";
import "flare/actor_color.dart";
import "flare/actor_node.dart";
import "flare/actor_drawable.dart";
import "dart:ui" as ui;
import "flare/math/mat2d.dart";
import "flare/math/vec2d.dart";
import "dart:math";
import "flare/path_point.dart";

export "flare/animation/actor_animation.dart";
export "flare/actor_node.dart";

import "package:flutter/services.dart" show rootBundle;

abstract class FlutterFill
{
	ui.Paint getPaint(Float64List transform, double opacity);
}

abstract class FlutterStroke
{
	ui.Paint getPaint(Float64List transform, double opacity);
}

class FlutterActorShape extends ActorShape
{
	List<FlutterFill> _fills;
	List<FlutterStroke> _flutterStrokes;
	ui.Path _path;

	@override
	void invalidateShape()
	{
		_path = null;
	}

	ui.Path get path
	{
		if(_path != null)
		{
			return _path;
		}
		_path = new ui.Path();
		_path.fillType = ui.PathFillType.nonZero;
		_path.reset();

		for(ActorNode node in children)
		{
			FlutterPath flutterPath = node as FlutterPath;
			if(flutterPath != null)
			{
		
				Mat2D transform = (node as ActorBasePath).pathTransform;
				_path.addPath(flutterPath.path, ui.Offset.zero, matrix4:transform == null ? null : transform.mat4);
			}
		}
		return _path;
		
	}

	void addFlutterStroke(FlutterStroke stroke)
	{
		if(_flutterStrokes == null)
		{
			_flutterStrokes = new List<FlutterStroke>();
		}
		_flutterStrokes.add(stroke);
	}

	void addFill(FlutterFill fill)
	{
		if(_fills == null)
		{
			_fills = new List<FlutterFill>();
		}
		_fills.add(fill);
	}

	List<ActorClip> getClips()
	{
		ActorNode clipSearch = this;
		List<ActorClip> clips;
		while(clipSearch != null)
		{
			if(clipSearch.clips != null)
			{
				clips = clipSearch.clips;
				break;
			}
			clipSearch = clipSearch.parent;
		}

		return clips;
	}

	void draw(ui.Canvas canvas, double opacity, ui.Color overrideColor)
	{
		opacity *= renderOpacity;
		if(opacity <= 0 || !this.doesDraw)
		{
			return;
		}

		canvas.save();

		ui.Path renderPath = path;
		Float64List paintTransform = worldTransform.mat4;
		
		// Get Clips
		List<ActorClip> clipList = getClips();
		if(clipList != null)
		{
			for(ActorClip clip in clipList)
			{
				clip.node.all((ActorNode childNode)
				{
					if(childNode is FlutterActorShape)
					{
						ui.Path clippingPath = childNode.path;
						canvas.clipPath(clippingPath);
					}
				});
			}
		}
		//canvas.transform(paintTransform);
		if(_fills != null)
		{
			for(FlutterFill fill in _fills)
			{
				ui.Paint paint = fill.getPaint(paintTransform, opacity);
				if(paint == null)
				{
					continue;
				}
				if(overrideColor != null)
				{
					paint.color = overrideColor.withOpacity(overrideColor.opacity*paint.color.opacity);
				}
				canvas.drawPath(renderPath, paint);
			}
		}
		if(_flutterStrokes != null)
		{
			for(FlutterStroke stroke in _flutterStrokes)
			{
				ui.Paint paint = stroke.getPaint(paintTransform, opacity);
				if(paint == null)
				{
					continue;
				}
				if(overrideColor != null)
				{
					paint.color = overrideColor.withOpacity(overrideColor.opacity*paint.color.opacity);
				}
				canvas.drawPath(renderPath, paint);
			}
		}

		canvas.restore();
	}

	ActorComponent makeInstance(ActorArtboard resetArtboard)
	{
		FlutterActorShape instanceNode = new FlutterActorShape();
		instanceNode.copyShape(this, resetArtboard);
		return instanceNode;
	}
}

class FlutterColorFill extends ColorFill implements FlutterFill
{
	ui.Paint getPaint(Float64List transform, double modulateOpacity)
	{
		ui.Paint paint = new ui.Paint()
									..color = new ui.Color.fromRGBO((color[0]*255.0).round(), (color[1]*255.0).round(), (color[2]*255.0).round(), color[3]*modulateOpacity*opacity)
									..style = ui.PaintingStyle.fill;
		return paint;
	}

	void completeResolve()
	{
		super.completeResolve();

		ActorNode parentNode = parent;
		if(parentNode is FlutterActorShape)
		{
			parentNode.addFill(this);
		}
	}

	ActorComponent makeInstance(ActorArtboard resetArtboard)
	{
		FlutterColorFill instanceNode = new FlutterColorFill();
		instanceNode.copyColorFill(this, resetArtboard);
		return instanceNode;
	}
}

class FlutterColorStroke extends ColorStroke implements FlutterStroke
{
	ui.Paint getPaint(Float64List transform, double modulateOpacity)
	{
		if(width == 0)
		{
			return null;
		}
		ui.Paint paint = new ui.Paint()
									..color = new ui.Color.fromRGBO((color[0]*255.0).round(), (color[1]*255.0).round(), (color[2]*255.0).round(), color[3]*modulateOpacity*opacity)
									..strokeWidth = width
									..style = ui.PaintingStyle.stroke;
		return paint;
	}

	void completeResolve()
	{
		super.completeResolve();

		ActorNode parentNode = parent;
		if(parentNode is FlutterActorShape)
		{
			parentNode.addFlutterStroke(this);
		}
	}

	ActorComponent makeInstance(ActorArtboard resetArtboard)
	{
		FlutterColorStroke instanceNode = new FlutterColorStroke();
		instanceNode.copyColorStroke(this, resetArtboard);
		return instanceNode;
	}
}

class FlutterGradientFill extends GradientFill implements FlutterFill
{
	ui.Paint getPaint(Float64List transform, double modulateOpacity)
	{
		List<ui.Color> colors = new List<ui.Color>();
    	List<double> stops = new List<double>();
		int numStops = (colorStops.length/5).round();

		int idx = 0;
		for(int i = 0; i < numStops; i++)
		{
			ui.Color color = new ui.Color.fromRGBO((colorStops[idx]*255.0).round(), (colorStops[idx+1]*255.0).round(), (colorStops[idx+2]*255.0).round(), colorStops[idx+3]);
			colors.add(color);
			stops.add(colorStops[idx+4]);
			idx += 5;
		}
		ui.Paint paint = new ui.Paint()
								..color = Colors.white.withOpacity(modulateOpacity*opacity)
								..shader = new ui.Gradient.linear(new ui.Offset(renderStart[0], renderStart[1]), new ui.Offset(renderEnd[0], renderEnd[1]), colors, stops)
								..style = ui.PaintingStyle.fill;
		return paint;
	}

	void completeResolve()
	{
		super.completeResolve();

		ActorNode parentNode = parent;
		if(parentNode is FlutterActorShape)
		{
			parentNode.addFill(this);
		}
	}

	ActorComponent makeInstance(ActorArtboard resetArtboard)
	{
		FlutterGradientFill instanceNode = new FlutterGradientFill();
		instanceNode.copyGradientFill(this, resetArtboard);
		return instanceNode;
	}
}

class FlutterGradientStroke extends GradientStroke implements FlutterStroke
{
	ui.Paint getPaint(Float64List transform, double modulateOpacity)
	{
		List<ui.Color> colors = new List<ui.Color>();
    	List<double> stops = new List<double>();
		int numStops = (colorStops.length/5).round();

		int idx = 0;
		for(int i = 0; i < numStops; i++)
		{
			ui.Color color = new ui.Color.fromRGBO((colorStops[idx]*255.0).round(), (colorStops[idx+1]*255.0).round(), (colorStops[idx+2]*255.0).round(), colorStops[idx+3]);
			colors.add(color);
			stops.add(colorStops[idx+4]);
			idx += 5;
		}

		ui.Paint paint = new ui.Paint()
								..color = Colors.white.withOpacity(modulateOpacity*opacity)
								..shader = new ui.Gradient.linear(new ui.Offset(renderStart[0], renderStart[1]), new ui.Offset(renderEnd[0], renderEnd[1]), colors, stops)
								..strokeWidth = width
								..style = ui.PaintingStyle.stroke;
		return paint;
	}

	void completeResolve()
	{
		super.completeResolve();

		ActorNode parentNode = parent;
		if(parentNode is FlutterActorShape)
		{
			parentNode.addFlutterStroke(this);
		}
	}

	ActorComponent makeInstance(ActorArtboard resetArtboard)
	{
		FlutterGradientStroke instanceNode = new FlutterGradientStroke();
		instanceNode.copyGradientStroke(this, resetArtboard);
		return instanceNode;
	}
}

class FlutterRadialFill extends RadialGradientFill implements FlutterFill
{
	ui.Paint getPaint(Float64List transform, double modulateOpacity)
	{
		// double squash = max(0.00001, secondaryRadiusScale);
		// Vec2D diff = Vec2D.subtract(new Vec2D(), end, start);
		// double angle = atan2(diff[1], diff[0]);
		// Mat2D transform = new Mat2D();

		// Mat2D translate = new Mat2D();
		// translate[4] = start[0];
		// translate[5] = start[1];

		// Mat2D rotation = new Mat2D();
		// Mat2D.fromRotation(rotation, angle);

		// transform[4] = start[0];
		// transform[5] = start[1];

		// Mat2D scaling = new Mat2D();
		// scaling[0] = 1.0;
		// scaling[3] = squash;

		// Mat2D.multiply(transform, translate, rotation);
		// Mat2D.multiply(transform, transform, scaling);

		double radius = Vec2D.distance(renderStart, renderEnd);
		List<ui.Color> colors = new List<ui.Color>();
    	List<double> stops = new List<double>();
		int numStops = (colorStops.length/5).round();

		int idx = 0;
		for(int i = 0; i < numStops; i++)
		{
			ui.Color color = new ui.Color.fromRGBO((colorStops[idx]*255.0).round(), (colorStops[idx+1]*255.0).round(), (colorStops[idx+2]*255.0).round(), colorStops[idx+3]);
			colors.add(color);
			stops.add(colorStops[idx+4]);
			idx += 5;
		}
		ui.Gradient radial = new ui.Gradient.radial(Offset(renderStart[0], renderStart[1]), radius, colors, stops, ui.TileMode.clamp);//, transform.mat4);
		ui.Paint paint = new ui.Paint()
								..color = Colors.white.withOpacity(modulateOpacity*opacity)
								..shader = radial
								..style = ui.PaintingStyle.fill;

		return paint;
	}

	void completeResolve()
	{
		super.completeResolve();

		ActorNode parentNode = parent;
		if(parentNode is FlutterActorShape)
		{
			parentNode.addFill(this);
		}
	}

	ActorComponent makeInstance(ActorArtboard resetArtboard)
	{
		FlutterRadialFill instanceNode = new FlutterRadialFill();
		instanceNode.copyRadialFill(this, resetArtboard);
		return instanceNode;
	}
}

class FlutterRadialStroke extends RadialGradientStroke implements FlutterStroke
{
	ui.Paint getPaint(Float64List transform, double modulateOpacity)
	{
        // double squash = max(0.00001, secondaryRadiusScale);
		// Vec2D diff = Vec2D.subtract(new Vec2D(), end, start);
		// double angle = atan2(diff[1], diff[0]);
		// Mat2D transform = new Mat2D();

		// Mat2D translate = new Mat2D();
		// translate[4] = start[0];
		// translate[5] = start[1];

		// Mat2D rotation = new Mat2D();
		// Mat2D.fromRotation(rotation, angle);

		// transform[4] = start[0];
		// transform[5] = start[1];

		// Mat2D scaling = new Mat2D();
		// scaling[0] = 1.0;
		// scaling[3] = squash;

		// Mat2D.multiply(transform, translate, rotation);
		// Mat2D.multiply(transform, transform, scaling);

		double radius = Vec2D.distance(renderStart, renderEnd);
		List<ui.Color> colors = new List<ui.Color>();
    	List<double> stops = new List<double>();
		int numStops = (colorStops.length/5).round();

		int idx = 0;
		for(int i = 0; i < numStops; i++)
		{
			ui.Color color = new ui.Color.fromRGBO((colorStops[idx]*255.0).round(), (colorStops[idx+1]*255.0).round(), (colorStops[idx+2]*255.0).round(), colorStops[idx+3]);
			colors.add(color);
			stops.add(colorStops[idx+4]);
			idx += 5;
		}
		return new ui.Paint()
								..color = Colors.white.withOpacity(modulateOpacity*opacity)
								..shader = new ui.Gradient.radial(Offset(renderStart[0], renderStart[1]), radius, colors, stops, ui.TileMode.clamp)//, transform.mat4)
								// ..shader = new ui.Gradient.radial(new ui.Offset(center[0], center[1]), radius, colors, stops)
								..strokeWidth = width
								..style = ui.PaintingStyle.stroke;
	}

	void completeResolve()
	{
		super.completeResolve();

		ActorNode parentNode = parent;
		if(parentNode is FlutterActorShape)
		{
			parentNode.addFlutterStroke(this);
		}
	}

	ActorComponent makeInstance(ActorArtboard resetArtboard)
	{
		FlutterRadialStroke instanceNode = new FlutterRadialStroke();
		instanceNode.copyRadialStroke(this, resetArtboard);
		return instanceNode;
	}
}

class FlutterActor extends Actor
{
    List<ui.Image> _images;

    List<ui.Image> get images
    {
        return _images;
    }

	ActorArtboard makeArtboard()
	{
		return new FlutterActorArtboard(this);
	}

	ActorShape makeShapeNode()
	{
		return new FlutterActorShape();
	}

    ActorPath makePathNode()
	{
		return new FlutterActorPath();
	}
    
    ActorRectangle makeRectangle()
    {
        return new FlutterActorRectangle();
    }

    ActorTriangle makeTriangle()
    {
        return new FlutterActorTriangle();
    }

    ActorStar makeStar()
    {
        return new FlutterActorStar();
    }

    ActorPolygon makePolygon()
    {
        return new FlutterActorPolygon();
    }

    ActorEllipse makeEllipse()
    {
        return new FlutterActorEllipse();
    }

	ColorFill makeColorFill()
	{
		return new FlutterColorFill();
	}

	ColorStroke makeColorStroke()
	{
		return new FlutterColorStroke();
	}

	GradientFill makeGradientFill()
	{
		return new FlutterGradientFill();
	}

	GradientStroke makeGradientStroke()
	{
		return new FlutterGradientStroke();
	}

	RadialGradientFill makeRadialFill()
	{
		return new FlutterRadialFill();
	}

	RadialGradientStroke makeRadialStroke()
	{
		return new FlutterRadialStroke();
	}

	Future<bool> loadFromBundle(String filename) async
	{
		Completer<bool> completer = new Completer<bool>();
		rootBundle.load(filename).then((ByteData data)
		{	
			super.load(data);
			completer.complete(true);
		});
		return completer.future;
	}

    dispose()
    {}
}

class FlutterActorArtboard extends ActorArtboard
{
	FlutterActorArtboard(FlutterActor actor) : super(actor);
	
    void advance(double seconds)
    {
        super.advance(seconds);
    }

	void draw(ui.Canvas canvas, {ui.Color overrideColor, double opacity = 1.0})
	{
		for(ActorDrawable drawable in drawableNodes)
		{
			if(drawable is FlutterActorShape)
			{
				drawable.draw(canvas, opacity, overrideColor);
			}
		}
	}
	
	ActorArtboard makeInstance()
    {
        FlutterActorArtboard artboardInstance = new FlutterActorArtboard(actor);
        artboardInstance.copyArtboard(this);
        return artboardInstance;
    }
	
	void dispose() {}
}

class FlutterActorPath extends ActorPath with FlutterPathPointsPath
{
	ActorComponent makeInstance(ActorArtboard resetArtboard)
	{
		FlutterActorPath instanceNode = new FlutterActorPath();
		instanceNode.copyPath(this, resetArtboard);
		return instanceNode;
	}
}

class FlutterActorEllipse extends ActorEllipse with FlutterPathPointsPath
{
	ActorComponent makeInstance(ActorArtboard resetArtboard)
	{
		FlutterActorEllipse instanceNode = new FlutterActorEllipse();
		instanceNode.copyPath(this, resetArtboard);
		return instanceNode;
	}
    // updatePath(ui.Path path)
    // {
    //     List<PathPoint> pts = points;
    //     int len = pts.length;
    //     path.moveTo(0.0, -radiusY);
        
    //     for(int i = 0; i < len; i++)
    //     {
    //         CubicPathPoint point = pts[i];
    //         CubicPathPoint nextPoint = pts[(i+1)%len];
    //         Vec2D t = nextPoint.translation;
    //         Vec2D cin = nextPoint.inPoint;
    //         Vec2D cout = point.outPoint;
    //         path.cubicTo(
    //             cout[0], cout[1],
    //             cin[0], cin[1],
    //             t[0], t[1]
    //         );
    //     }
    //     path.close();
    // }

}

class FlutterActorPolygon extends ActorPolygon with FlutterPathPointsPath
{
	ActorComponent makeInstance(ActorArtboard resetArtboard)
	{
		FlutterActorPolygon instanceNode = new FlutterActorPolygon();
		instanceNode.copyPolygon(this, resetArtboard);
		return instanceNode;
	}
    // updatePath(ui.Path path)
    // {
    //     Mat2D xform = this.transform;
    //     List<PathPoint> pts = points;
    //     for(PathPoint p in pts)
    //     {
    //         p = p.transformed(xform);
    //     }

    //     path.moveTo(0.0, -radiusY);
    //     double angle = -pi/2.0;
    //     double inc = (pi*2.0)/sides;

    //     for(int i = 0; i < sides; i++)
    //     {
    //         path.lineTo(cos(angle)*radiusX, sin(angle)*radiusY);
    //         angle += inc;
    //     }

    //     path.close();
    // }
}

class FlutterActorStar extends ActorStar with FlutterPathPointsPath
{
	ActorComponent makeInstance(ActorArtboard resetArtboard)
	{
		FlutterActorStar instanceNode = new FlutterActorStar();
		instanceNode.copyStar(this, resetArtboard);
		return instanceNode;
	}
    // onPathInvalid()
    // {
    //     (parent as FlutterActorShape).invalidatePath();
    // }

    // markPathDirty()
    // {
    //     actor.addDirt(this, ActorBasePath.PathDirty, false);
    //     this.onPathInvalid();
    // }

    // updatePath(ui.Path path)
    // {
    //     path.moveTo(0.0, -radiusY);
    //     double angle = -pi/2.0;
    //     double inc = (pi*2.0)/sides;
    //     Vec2D sx = Vec2D.fromValues(radiusX, radiusX*innerRadius);
    //     Vec2D sy = Vec2D.fromValues(radiusY, radiusY*innerRadius);
        
    //     for(int i = 0; i < sides; i++)
    //     {
    //         path.lineTo(cos(angle)*sx[i%2], sin(angle)*sy[i%2]);
    //         angle += inc;
    //     }
    //     path.close();
    // }
}

// Example of how to directly use a base FlutterPath and do drawing directly with SKIA high level paths
// This is more efficient, particularly when using a lot of procedural shapes.
class FlutterActorRectangle extends ActorRectangle with FlutterPath
{
	ActorComponent makeInstance(ActorArtboard resetArtboard)
	{
		FlutterActorRectangle instanceNode = new FlutterActorRectangle();
		instanceNode.copyRectangle(this, resetArtboard);
		return instanceNode;
	}

	ui.Path _path;

    ui.Path get path
	{
		if(_path != null)
		{
			return _path;
		}
		return (_path = _makePath());
	}
	
	@override
	void invalidatePath()
    {
        _path = null;
    }

	ui.Path _makePath()
	{
		ui.Path p = new ui.Path();
		double halfWidth = width/2.0;
		double halfHeight = height/2.0;
        Vec2D topLeft = Vec2D.fromValues(-halfWidth, halfHeight);       
        Vec2D bottomRight = Vec2D.fromValues(halfWidth, -halfHeight);
        p.moveTo(x, y);

        p.addRRect(
            new ui.RRect.fromLTRBR(
                topLeft[0],
                topLeft[1],
                bottomRight[0],
                bottomRight[1],
                ui.Radius.circular(radius)
            )
        );

		return p;
    }
}

class FlutterActorTriangle extends ActorTriangle with FlutterPathPointsPath
{
	ActorComponent makeInstance(ActorArtboard resetArtboard)
	{
		FlutterActorTriangle instanceNode = new FlutterActorTriangle();
		instanceNode.copyPath(this, resetArtboard);
		return instanceNode;
	}
    // updatePath(ui.Path path)
    // {
    //     path.moveTo(0.0, -radiusY);
    //     path.lineTo(radiusX, radiusY);
    //     path.lineTo(-radiusX, radiusY);
    //     path.close();
    // }
}

// Abstract base path that can be invalidated and somehow regenerates, no concrete logic
abstract class FlutterPath
{
    ui.Path get path;
}

// Abstract path that uses Actor PathPoints, slightly higher level that FlutterPath.
// Most shapes can use this, but if they want to use a different procedural backing call,
// they should implement FlutterPath and generate the path another way.
abstract class FlutterPathPointsPath implements FlutterPath
{
	ui.Path _path;
	List<PathPoint> get deformedPoints;
	bool get isClosed;   

    ui.Path get path
	{
		if(_path != null)
		{
			return _path;
		}
		return (_path = _makePath());
	}
	
	void invalidatePath()
    {
        _path = null;
    }

	ui.Path _makePath()
	{
		ui.Path p = new ui.Path();

		List<PathPoint> pts = this.deformedPoints;
		if(pts == null || pts.length == 0)
		{
			return p;
		}
		
		List<PathPoint> renderPoints = new List<PathPoint>();
		int pl = pts.length;
		
		const double arcConstant = 0.55;
		const double iarcConstant = 1.0-arcConstant;
		PathPoint previous = isClosed ? pts[pl-1] : null;
		for(int i = 0; i < pl; i++)
		{
			PathPoint point = pts[i];
			switch(point.pointType)
			{
				case PointType.Straight:
				{
					StraightPathPoint straightPoint = point as StraightPathPoint;
					double radius = straightPoint.radius;
					if(radius > 0)
					{
						if(!isClosed && (i == 0 || i == pl-1))
						{
							renderPoints.add(point);
							previous = point;
						}
						else
						{
							PathPoint next = pts[(i+1)%pl];
							Vec2D prevPoint = previous is CubicPathPoint ? previous.outPoint : previous.translation;
							Vec2D nextPoint = next is CubicPathPoint ? next.inPoint : next.translation;
							Vec2D pos = point.translation;

							Vec2D toPrev = Vec2D.subtract(new Vec2D(), prevPoint, pos);
							double toPrevLength = Vec2D.length(toPrev);
							toPrev[0] /= toPrevLength;
							toPrev[1] /= toPrevLength;

							Vec2D toNext = Vec2D.subtract(new Vec2D(), nextPoint, pos);
							double toNextLength = Vec2D.length(toNext);
							toNext[0] /= toNextLength;
							toNext[1] /= toNextLength;

							double renderRadius = min(toPrevLength, min(toNextLength, radius));

							Vec2D translation = Vec2D.scaleAndAdd(new Vec2D(), pos, toPrev, renderRadius);
							renderPoints.add(new CubicPathPoint.fromValues(translation, translation, Vec2D.scaleAndAdd(new Vec2D(), pos, toPrev, iarcConstant*renderRadius)));
							translation = Vec2D.scaleAndAdd(new Vec2D(), pos, toNext, renderRadius);
							previous = new CubicPathPoint.fromValues(translation, Vec2D.scaleAndAdd(new Vec2D(), pos, toNext, iarcConstant*renderRadius), translation);
							renderPoints.add(previous);
						}
					}
					else
					{
						renderPoints.add(point);
						previous = point;
					}
					break;
				}
				default:
					renderPoints.add(point);
					previous = point;
					break;
			}
		}

		PathPoint firstPoint = renderPoints[0];
		p.moveTo(firstPoint.translation[0], firstPoint.translation[1]);
		for(int i = 0, l = isClosed ? renderPoints.length : renderPoints.length-1, pl = renderPoints.length; i < l; i++)
		{
			PathPoint point = renderPoints[i];
			PathPoint nextPoint = renderPoints[(i+1)%pl];
			Vec2D cin = nextPoint is CubicPathPoint ? nextPoint.inPoint : null;
            Vec2D cout = point is CubicPathPoint ? point.outPoint : null;
			if(cin == null && cout == null)
			{
				p.lineTo(nextPoint.translation[0], nextPoint.translation[1]);	
			}
			else
			{
				if(cout == null)
				{
					cout = point.translation;
				}
				if(cin == null)
				{
					cin = nextPoint.translation;
				}

				p.cubicTo(
					cout[0], cout[1],

					cin[0], cin[1],

					nextPoint.translation[0], nextPoint.translation[1]);
			}
		}

		if(isClosed)
		{
			p.close();
		}

		return p;
	}
}