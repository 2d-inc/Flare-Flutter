library flare;

import "dart:async";
import "dart:typed_data";

import "actor.dart";
import "actor_shape.dart";
import "actor_path.dart";
import "actor_ellipse.dart";
import "actor_color.dart";
import "actor_node.dart";
import "actor_drawable.dart";
import "dart:ui" as ui;
import "math/mat2d.dart";
import "math/vec2d.dart";
import "dart:math";

export "animation/actor_animation.dart";
export "actor_node.dart";

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
	List<FlutterStroke> _strokes;
	ui.Path _path;

	void invalidatePath()
	{
		_path = null;
	}

	ui.Path updatePath()
	{
		if(_path != null)
		{
			return _path;
		}
		_path = new ui.Path();
		_path.fillType = ui.PathFillType.nonZero;
		_path.reset();

		for(ActorBasePath path in children)
		{
			if(path == null)
			{
				continue;
			}
			path.updatePath(_path);
		}
		return _path;
		
	}

	void addStroke(FlutterStroke stroke)
	{
		if(_strokes == null)
		{
			_strokes = new List<FlutterStroke>();
		}
		_strokes.add(stroke);
	}

	void addFill(FlutterFill fill)
	{
		if(_fills == null)
		{
			_fills = new List<FlutterFill>();
		}
		_fills.add(fill);
	}

	void draw(ui.Canvas canvas)
	{
		if(!this.doesDraw)
		{
			return;
		}

		canvas.save();

		ui.Path path = updatePath();
		Float64List paintTransform = worldTransform.mat4;
		
		double opacity = this.renderOpacity;

		// Get Clips
		if(clips != null)
		{
			for(ActorClip clip in clips)
			{
				clip.node.all((ActorNode childNode)
				{
					if(childNode is FlutterActorShape)
					{
						ui.Path path = childNode.updatePath();

						canvas.clipPath(path.transform(childNode.worldTransform.mat4));
					}
				});
			}
		}
		canvas.transform(paintTransform);
		if(_fills != null)
		{
			for(FlutterFill fill in _fills)
			{
				ui.Paint paint = fill.getPaint(paintTransform, opacity);
				if(paint == null)
				{
					continue;
				}
				canvas.drawPath(path, paint);
			}
		}
		if(_strokes != null)
		{
			for(FlutterStroke stroke in _strokes)
			{
				ui.Paint paint = stroke.getPaint(paintTransform, opacity);
				if(paint == null)
				{
					continue;
				}
				canvas.drawPath(path, paint);
			}
		}

		canvas.restore();
	}
}

class FlutterColorFill extends ColorFill implements FlutterFill
{
	ui.Paint getPaint(Float64List transform, double opacity)
	{
		ui.Paint paint = new ui.Paint()
									..color = new ui.Color.fromARGB((color[3]*opacity*255.0).round(), (color[0]*255.0).round(), (color[1]*255.0).round(), (color[2]*255.0).round())
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
}

class FlutterColorStroke extends ColorStroke implements FlutterStroke
{
	ui.Paint getPaint(Float64List transform, double opacity)
	{
		if(width == 0)
		{
			return null;
		}
		ui.Paint paint = new ui.Paint()
									..color = new ui.Color.fromARGB((color[3]*opacity*255.0).round(), (color[0]*255.0).round(), (color[1]*255.0).round(), (color[2]*255.0).round())
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
			parentNode.addStroke(this);
		}
	}
}

class FlutterGradientFill extends GradientFill implements FlutterFill
{
	ui.Paint getPaint(Float64List transform, double opacity)
	{
		List<ui.Color> colors = new List<ui.Color>();
    	List<double> stops = new List<double>();
		int numStops = (colorStops.length/5).round();

		int idx = 0;
		for(int i = 0; i < numStops; i++)
		{
			ui.Color color = new ui.Color.fromARGB((colorStops[idx+3]*opacity*255.0).round(), (colorStops[idx]*255.0).round(), (colorStops[idx+1]*255.0).round(), (colorStops[idx+2]*255.0).round());
			colors.add(color);
			stops.add(colorStops[idx+4]);
			idx += 5;
		}
		Vec2D gstart = start;
		Vec2D gend = end;

		ui.Paint paint = new ui.Paint()
								..color = new ui.Color.fromARGB((opacity*255.0).round(), 255, 255, 255)
								..shader = new ui.Gradient.linear(new ui.Offset(gstart[0], gstart[1]), new ui.Offset(gend[0], gend[1]), colors, stops)
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
}

class FlutterGradientStroke extends GradientStroke implements FlutterStroke
{
	ui.Paint getPaint(Float64List transform, double opacity)
	{
		List<ui.Color> colors = new List<ui.Color>();
    	List<double> stops = new List<double>();
		int numStops = (colorStops.length/5).round();

		int idx = 0;
		for(int i = 0; i < numStops; i++)
		{
			ui.Color color = new ui.Color.fromARGB((colorStops[idx+3]*opacity*255.0).round(), (colorStops[idx]*255.0).round(), (colorStops[idx+1]*255.0).round(), (colorStops[idx+2]*255.0).round());
			colors.add(color);
			stops.add(colorStops[idx+4]);
			idx += 5;
		}

		Vec2D gstart = start;
		Vec2D gend = end;
		ui.Paint paint = new ui.Paint()
								..color = new ui.Color.fromARGB((opacity*255.0).round(), 255, 255, 255)
								..shader = new ui.Gradient.linear(new ui.Offset(gstart[0], gstart[1]), new ui.Offset(gend[0], gend[1]), colors, stops)
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
			parentNode.addStroke(this);
		}
	}
}

double R = 0.0;
class FlutterRadialFill extends RadialGradientFill implements FlutterFill
{
	ui.Paint getPaint(Float64List transform, double opacity)
	{
		/*let {_Start:start, _End:end, _ColorStops:stops, _SecondaryRadiusScale:secondaryRadiusScale} = this;
		var gradient = ctx.createRadialGradient(0.0, 0.0, 0.0, 0.0, 0.0, vec2.distance(start, end));

		const numStops = stops.length/5;
		let idx = 0;
		for(let i = 0; i < numStops; i++)
		{
			const style = "rgba(" + Math.round(stops[idx++]*255) + ", " + Math.round(stops[idx++]*255) + ", " + Math.round(stops[idx++]*255) + ", " + stops[idx++] + ")";
			const value = stops[idx++];
			gradient.addColorStop(value, style);
		}
		
		ctx.fillStyle = gradient;

		const squash = Math.max(0.00001, secondaryRadiusScale);

		let angle = vec2.getAngle(vec2.subtract(vec2.create(), end, start));
		ctx.save();
		ctx.translate(start[0], start[1]);
		ctx.rotate(angle);
		ctx.scale(1.0, squash);*/
		double squash = max(0.00001, secondaryRadiusScale);
		Vec2D diff = Vec2D.subtract(new Vec2D(), end, start);
		double angle = atan2(diff[1], diff[0]);
		Mat2D transform = new Mat2D();

		Mat2D translate = new Mat2D();
		translate[4] = start[0];
		translate[5] = start[1];

		Mat2D rotation = new Mat2D();
		Mat2D.fromRotation(rotation, angle+R);
		R += 0.01;

		transform[4] = start[0];
		transform[5] = start[1];

		Mat2D scaling = new Mat2D();
		scaling[0] = 1.0;
		scaling[3] = squash;

		Mat2D.multiply(transform, translate, rotation);
		Mat2D.multiply(transform, transform, scaling);
		//Mat2D.scale(transform, transform, new Vec2D.fromValues(1.0, squash));
		/*Vec2D.normalize(diff, diff);
		Mat2D transform = new Mat2D();
		transform[0] = diff[0];
		transform[1] = diff[1];
		transform[2] = diff[1] * squash;
		transform[3] = -diff[0] * squash;*/

		double radius = Vec2D.distance(start, end);
		List<ui.Color> colors = new List<ui.Color>();
    	List<double> stops = new List<double>();
		int numStops = (colorStops.length/5).round();

		int idx = 0;
		for(int i = 0; i < numStops; i++)
		{
			ui.Color color = new ui.Color.fromARGB((colorStops[idx+3]*255.0).round(), (colorStops[idx]*255.0).round(), (colorStops[idx+1]*255.0).round(), (colorStops[idx+2]*255.0).round());
			colors.add(color);
			stops.add(colorStops[idx+4]);
			idx += 5;
		}
		Vec2D center = start;
		ui.Gradient radial = new ui.Gradient.radial(new ui.Offset(0.0, 0.0), radius, colors, stops, ui.TileMode.clamp, transform.mat4);
		//print("RADIUS ${center[0]} ${center[1]} ${colors.length} $numStops ${colors} ${stops}");
		ui.Paint paint = new ui.Paint()
								..color = new ui.Color.fromARGB((opacity*255.0).round(), 255, 255, 255)
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
}

class FlutterRadialStroke extends RadialGradientStroke implements FlutterStroke
{
	ui.Paint getPaint(Float64List transform, double opacity)
	{
        double squash = max(0.00001, secondaryRadiusScale);
		Vec2D diff = Vec2D.subtract(new Vec2D(), end, start);
		double angle = atan2(diff[1], diff[0]);
		Mat2D transform = new Mat2D();

		Mat2D translate = new Mat2D();
		translate[4] = start[0];
		translate[5] = start[1];

		Mat2D rotation = new Mat2D();
		Mat2D.fromRotation(rotation, angle+R);
		R += 0.01;

		transform[4] = start[0];
		transform[5] = start[1];

		Mat2D scaling = new Mat2D();
		scaling[0] = 1.0;
		scaling[3] = squash;

		Mat2D.multiply(transform, translate, rotation);
		Mat2D.multiply(transform, transform, scaling);

		double radius = Vec2D.distance(start, end);
		List<ui.Color> colors = new List<ui.Color>();
    	List<double> stops = new List<double>();
		int numStops = (colorStops.length/5).round();

		int idx = 0;
		for(int i = 0; i < numStops; i++)
		{
			ui.Color color = new ui.Color.fromARGB((colorStops[idx+3]*255.0).round(), (colorStops[idx]*255.0).round(), (colorStops[idx+1]*255.0).round(), (colorStops[idx+2]*255.0).round());
			colors.add(color);
			stops.add(colorStops[idx+4]);
			idx += 5;
		}
		Vec2D center = start;
		return new ui.Paint()
								..color = new ui.Color.fromARGB((opacity*255.0).round(), 255, 255, 255)
								..shader = new ui.Gradient.radial(new ui.Offset(0.0, 0.0), radius, colors, stops, ui.TileMode.clamp, transform.mat4)
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
			parentNode.addStroke(this);
		}
	}
}

class FlutterActor extends Actor
{
    bool _isInstance = false;
    List<ui.Image> _images;

    List<ui.Image> get images
    {
        return _images;
    }

	ActorShape makeShapeNode()
	{
		return new FlutterActorShape();
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
		print("Loading actor filename $filename");
		ByteData data = await rootBundle.load(filename);
		super.load(data);

		// List<Future<ui.Codec>> waitList = new List<Future<ui.Codec>>();
		// _images = new List<ui.Image>(texturesUsed);

		// for(int i = 0; i < texturesUsed; i++)
		// {
		// 	String atlasFilename;
		// 	if(texturesUsed == 1)
		// 	{
		// 		atlasFilename = filename + ".png";
		// 	}
		// 	else
		// 	{
		// 		atlasFilename = filename + i.toString() + ".png";
		// 	}
		// 	ByteData data = await rootBundle.load(atlasFilename);
		// 	Uint8List list = new Uint8List.view(data.buffer);
		// 	waitList.add(ui.instantiateImageCodec(list));
		// }

		// List<ui.Codec> codecs = await Future.wait(waitList);
		// List<ui.FrameInfo> frames = await Future.wait(codecs.map((codec) => codec.getNextFrame()));
		// for(int i = 0; i < frames.length; i++)
		// {
		// 	_images[i] = frames[i].image;
		// }

		// for(FlutterActorImage image in imageNodes)
		// {
		// 	image.init();
		// }

		return true;
	}

    Actor makeInstance()
    {
        FlutterActor actorInstance = new FlutterActor();
        actorInstance.copyActor(this);
        actorInstance._isInstance = true;
        // TODO: copy Images
        return actorInstance;
    }

    void advance(double seconds)
    {
        super.advance(seconds);
    }

    dispose()
    {}

	void draw(ui.Canvas canvas)
	{
		for(ActorDrawable drawable in drawableNodes)
		{
			if(drawable is FlutterActorShape)
			{
				drawable.draw(canvas);
			}
		}
	}
}