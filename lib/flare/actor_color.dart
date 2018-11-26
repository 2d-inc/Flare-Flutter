import "dart:typed_data";
import 'math/mat2d.dart';

import "actor_node.dart";
import "actor_shape.dart";
import "actor_artboard.dart";

import "actor.dart";
import "actor_component.dart";
import "dart:collection";
import "stream_reader.dart";
import "math/vec2d.dart";

enum FillRule
{
	EvenOdd,
	NonZero
}

HashMap<int,FillRule> fillRuleLookup = new HashMap<int,FillRule>.fromIterables([0,1], [FillRule.EvenOdd, FillRule.NonZero]);

abstract class ActorPaint extends ActorComponent
{
	double opacity = 1.0;

	void copyPaint(ActorPaint component, ActorArtboard resetArtboard)
	{
		copyComponent(component, resetArtboard);
		opacity = component.opacity;
	}

	static ActorPaint read(ActorArtboard artboard, StreamReader reader, ActorPaint component)
	{
		ActorComponent.read(artboard, reader, component);
		component.opacity = reader.readFloat32("opacity");

		return component;
	}

	completeResolve()
	{
		artboard.addDependency(this, parent);
	}
}

abstract class ActorColor extends ActorPaint
{
	Float32List _color = new Float32List(4);

	Float32List get color
	{
		return _color;
	}

	void copyColor(ActorColor node, ActorArtboard resetArtboard)
	{
		copyPaint(node, resetArtboard);
		_color[0] = node._color[0];
		_color[1] = node._color[1];
		_color[2] = node._color[2];
		_color[3] = node._color[3];
	}

	static ActorColor read(ActorArtboard artboard, StreamReader reader, ActorColor component)
	{
		ActorPaint.read(artboard, reader, component);

		reader.readFloat32ArrayOffset(component._color, 4, 0, "color");
		
		return component;
	}

	void onDirty(int dirt) {}
	void update(int dirt) {}
}

class ColorFill extends ActorColor
{
	FillRule _fillRule = FillRule.EvenOdd;

	ActorComponent makeInstance(ActorArtboard resetArtboard)
	{
		ColorFill instanceEvent = new ColorFill();
		instanceEvent.copyColorFill(this, resetArtboard);
		return instanceEvent;
	}

	void copyColorFill(ColorFill node, ActorArtboard resetArtboard)
	{
		copyColor(node, resetArtboard);
		_fillRule = node._fillRule;
	}

	static ColorFill read(ActorArtboard artboard, StreamReader reader, ColorFill component)
	{
		if(component == null)
		{
			component = new ColorFill();
		}
		ActorColor.read(artboard, reader, component);
		component._fillRule = fillRuleLookup[reader.readUint8("fillRule")];	
		return component;
	}
}

abstract class ActorStroke
{
	double get width;
}

class ColorStroke extends ActorColor implements ActorStroke
{
	double width = 1.0;

    double get opacity => _color[3];

    set opacity(double val)
    {
        this.color[3] = val;
    }
	
	ActorComponent makeInstance(ActorArtboard resetArtboard)
	{
		ColorStroke instanceEvent = new ColorStroke();
		instanceEvent.copyColorStroke(this, resetArtboard);
		return instanceEvent;
	}

	void copyColorStroke(ColorStroke node, ActorArtboard resetArtboard)
	{
		copyColor(node, resetArtboard);
		width = node.width;
	}

	static ColorStroke read(ActorArtboard artboard, StreamReader reader, ColorStroke component)
	{
		if(component == null)
		{
			component = new ColorStroke();
		}
		ActorColor.read(artboard, reader, component);
		component.width = reader.readFloat32("width");
		return component;
	}

	void completeResolve()
	{
		super.completeResolve();

		ActorNode parentNode = parent;
		if(parentNode is ActorShape)
		{
			parentNode.addStroke(this);
		}
	}
}

abstract class GradientColor extends ActorPaint
{
	Float32List _colorStops = new Float32List(10);
	Vec2D _start = new Vec2D();
	Vec2D _end = new Vec2D();
	Vec2D _renderStart = new Vec2D();
	Vec2D _renderEnd = new Vec2D();
    double opacity = 1.0;

	Vec2D get start => _start;
	Vec2D get end => _end;
	Vec2D get renderStart => _renderStart;
	Vec2D get renderEnd => _renderEnd;

	Float32List get colorStops
	{
		return _colorStops;
	}

	void copyGradient(GradientColor node, ActorArtboard resetArtboard)
	{
		copyPaint(node, resetArtboard);
		_colorStops = new Float32List.fromList(node._colorStops);
		Vec2D.copy(_start, node._start);
		Vec2D.copy(_end, node._end);
        opacity = node.opacity;
	}

	static GradientColor read(ActorArtboard artboard, StreamReader reader, GradientColor component)
	{
		ActorPaint.read(artboard, reader, component);

		int numStops = reader.readUint8("numColorStops");
		Float32List stops = new Float32List(numStops*5);
		reader.readFloat32ArrayOffset(stops, numStops*5, 0, "colorStops");
		component._colorStops = stops;

		reader.readFloat32ArrayOffset(component._start.values, 2, 0, "start");
		reader.readFloat32ArrayOffset(component._end.values, 2, 0, "end");
		
		return component;
	}

	void onDirty(int dirt) {}
	void update(int dirt) 
	{
		ActorShape shape = parent;
		Mat2D world = shape.worldTransform;
		Vec2D.transformMat2D(_renderStart, _start, world);
		Vec2D.transformMat2D(_renderEnd, _end, world);
	}
}

class GradientFill extends GradientColor
{
	FillRule _fillRule = FillRule.EvenOdd;

	ActorComponent makeInstance(ActorArtboard resetArtboard)
	{
		GradientFill instanceEvent = new GradientFill();
		instanceEvent.copyGradientFill(this, resetArtboard);
		return instanceEvent;
	}

	void copyGradientFill(GradientFill node, ActorArtboard resetArtboard)
	{
		copyGradient(node, resetArtboard);
		_fillRule = node._fillRule;
	}

	static GradientFill read(ActorArtboard artboard, StreamReader reader, GradientFill component)
	{
		if(component == null)
		{
			component = new GradientFill();
		}
		GradientColor.read(artboard, reader, component);
		component._fillRule = fillRuleLookup[reader.readUint8("fillRule")];	
		return component;
	}
}

class GradientStroke extends GradientColor implements ActorStroke
{
	double width = 1.0;

	ActorComponent makeInstance(ActorArtboard resetArtboard)
	{
		GradientStroke instanceEvent = new GradientStroke();
		instanceEvent.copyGradientStroke(this, resetArtboard);
		return instanceEvent;
	}

	void copyGradientStroke(GradientStroke node, ActorArtboard resetArtboard)
	{
		copyGradient(node, resetArtboard);
		width = node.width;
	}

	static GradientStroke read(ActorArtboard artboard, StreamReader reader, GradientStroke component)
	{
		if(component == null)
		{
			component = new GradientStroke();
		}
		GradientColor.read(artboard, reader, component);
		component.width = reader.readFloat32("width");
		return component;
	}

	void completeResolve()
	{
		super.completeResolve();

		ActorNode parentNode = parent;
		if(parentNode is ActorShape)
		{
			parentNode.addStroke(this);
		}
	}
}


abstract class RadialGradientColor extends GradientColor
{
	double secondaryRadiusScale = 1.0;

	void copyRadialGradient(RadialGradientColor node, ActorArtboard resetArtboard)
	{
		copyGradient(node, resetArtboard);
		secondaryRadiusScale = node.secondaryRadiusScale;
	}

	static RadialGradientColor read(ActorArtboard artboard, StreamReader reader, RadialGradientColor component)
	{
		GradientColor.read(artboard, reader, component);

		component.secondaryRadiusScale = reader.readFloat32("secondaryRadiusScale");
		
		return component;
	}
}

class RadialGradientFill extends RadialGradientColor
{
	FillRule _fillRule = FillRule.EvenOdd;

	ActorComponent makeInstance(ActorArtboard resetArtboard)
	{
		RadialGradientFill instanceEvent = new RadialGradientFill();
		instanceEvent.copyRadialFill(this, resetArtboard);
		return instanceEvent;
	}

	void copyRadialFill(RadialGradientFill node, ActorArtboard resetArtboard)
	{
		copyRadialGradient(node, resetArtboard);
		_fillRule = node._fillRule;
	}

	static RadialGradientFill read(ActorArtboard artboard, StreamReader reader, RadialGradientFill component)
	{
		if(component == null)
		{
			component = new RadialGradientFill();
		}
		RadialGradientColor.read(artboard, reader, component);
		component._fillRule = fillRuleLookup[reader.readUint8("fillRule")];	
		return component;
	}
}

class RadialGradientStroke extends RadialGradientColor implements ActorStroke
{
	double width = 1.0;
	
	ActorComponent makeInstance(ActorArtboard resetArtboard)
	{
		RadialGradientStroke instanceEvent = new RadialGradientStroke();
		instanceEvent.copyRadialStroke(this, resetArtboard);
		return instanceEvent;
	}

	void copyRadialStroke(RadialGradientStroke node, ActorArtboard resetArtboard)
	{
		copyRadialGradient(node, resetArtboard);
		width = node.width;
	}

	static RadialGradientStroke read(ActorArtboard artboard, StreamReader reader, RadialGradientStroke component)
	{
		if(component == null)
		{
			component = new RadialGradientStroke();
		}
		RadialGradientColor.read(artboard, reader, component);
		component.width = reader.readFloat32("width");
		return component;
	}

	void completeResolve()
	{
		super.completeResolve();

		ActorNode parentNode = parent;
		if(parentNode is ActorShape)
		{
			parentNode.addStroke(this);
		}
	}
}