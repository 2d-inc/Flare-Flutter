import 'dart:typed_data';
import 'package:flare/actor.dart';
import "actor_component.dart";
import "dart:collection";
import "binary_reader.dart";
import "math/vec2d.dart";

enum FillRule
{
	EvenOdd,
	NonZero
}

HashMap<int,FillRule> fillRuleLookup = new HashMap<int,FillRule>.fromIterables([0,1], [FillRule.EvenOdd, FillRule.NonZero]);

abstract class ActorColor extends ActorComponent
{
	Float32List _color = new Float32List(4);

	Float32List get color
	{
		return _color;
	}

	void copyColor(ActorColor node, Actor resetActor)
	{
		copyComponent(node, resetActor);
		_color[0] = node._color[0];
		_color[1] = node._color[1];
		_color[2] = node._color[2];
		_color[3] = node._color[3];
	}

	static ActorColor read(Actor actor, BinaryReader reader, ActorColor component)
	{
		ActorComponent.read(actor, reader, component);

		reader.readFloat32Array(component._color, 4, 0);
		
		return component;
	}

  	void completeResolve() {}
	void onDirty(int dirt) {}
	void update(int dirt) {}
}

class ColorFill extends ActorColor
{
	FillRule _fillRule = FillRule.EvenOdd;

	ActorComponent makeInstance(Actor resetActor)
	{
		ColorFill instanceEvent = new ColorFill();
		instanceEvent.copyColorFill(this, resetActor);
		return instanceEvent;
	}

	void copyColorFill(ColorFill node, Actor resetActor)
	{
		copyColor(node, resetActor);
		_fillRule = node._fillRule;
	}

	static ColorFill read(Actor actor, BinaryReader reader, ColorFill component)
	{
		if(component == null)
		{
			component = new ColorFill();
		}
		ActorColor.read(actor, reader, component);
		component._fillRule = fillRuleLookup[reader.readUint8()];	
		return component;
	}
}

class ColorStroke extends ActorColor
{
	double _width = 1.0;

	double get width
	{
		return _width;
	}
	
	ActorComponent makeInstance(Actor resetActor)
	{
		ColorStroke instanceEvent = new ColorStroke();
		instanceEvent.copyColorStroke(this, resetActor);
		return instanceEvent;
	}

	void copyColorStroke(ColorStroke node, Actor resetActor)
	{
		copyColor(node, resetActor);
		_width = node._width;
	}

	static ColorStroke read(Actor actor, BinaryReader reader, ColorStroke component)
	{
		if(component == null)
		{
			component = new ColorStroke();
		}
		ActorColor.read(actor, reader, component);
		component._width = reader.readFloat32();
		return component;
	}
}

abstract class GradientColor extends ActorComponent
{
	Float32List _colorStops = new Float32List(10);
	Vec2D _start = new Vec2D();
	Vec2D _end = new Vec2D();

	Vec2D get start
	{
		return _start;
	}

	Vec2D get end
	{
		return _end;
	}

	Vec2D get startWorld
	{
		return Vec2D.transformMat2D(new Vec2D(), _start, parent.worldTransform);
	}

	Vec2D get endWorld
	{
		return Vec2D.transformMat2D(new Vec2D(), _end, parent.worldTransform);
	}

	Float32List get colorStops
	{
		return _colorStops;
	}

	void copyGradient(GradientColor node, Actor resetActor)
	{
		copyComponent(node, resetActor);
		_colorStops = new Float32List.fromList(node._colorStops);
		Vec2D.copy(_start, node._start);
		Vec2D.copy(_end, node._end);
	}

	static GradientColor read(Actor actor, BinaryReader reader, GradientColor component)
	{
		ActorComponent.read(actor, reader, component);

		int numStops = reader.readUint8();
		Float32List stops = new Float32List(numStops*5);
		reader.readFloat32Array(stops, numStops*5, 0);
		component._colorStops = stops;

		reader.readFloat32Array(component._start.values, 2, 0);
		reader.readFloat32Array(component._end.values, 2, 0);
		
		return component;
	}

  	void completeResolve() {}
	void onDirty(int dirt) {}
	void update(int dirt) {}
}

class GradientFill extends GradientColor
{
	FillRule _fillRule = FillRule.EvenOdd;

	ActorComponent makeInstance(Actor resetActor)
	{
		GradientFill instanceEvent = new GradientFill();
		instanceEvent.copyColorFill(this, resetActor);
		return instanceEvent;
	}

	void copyColorFill(GradientFill node, Actor resetActor)
	{
		copyGradient(node, resetActor);
		_fillRule = node._fillRule;
	}

	static GradientFill read(Actor actor, BinaryReader reader, GradientFill component)
	{
		if(component == null)
		{
			component = new GradientFill();
		}
		GradientColor.read(actor, reader, component);
		component._fillRule = fillRuleLookup[reader.readUint8()];	
		return component;
	}
}

class GradientStroke extends GradientColor
{
	double _width = 1.0;

	double get width
	{
		return _width;
	}
	
	ActorComponent makeInstance(Actor resetActor)
	{
		GradientStroke instanceEvent = new GradientStroke();
		instanceEvent.copyGradientStroke(this, resetActor);
		return instanceEvent;
	}

	void copyGradientStroke(GradientStroke node, Actor resetActor)
	{
		copyGradient(node, resetActor);
		_width = node._width;
	}

	static GradientStroke read(Actor actor, BinaryReader reader, GradientStroke component)
	{
		if(component == null)
		{
			component = new GradientStroke();
		}
		GradientColor.read(actor, reader, component);
		component._width = reader.readFloat32();
		return component;
	}
}


abstract class RadialGradientColor extends GradientColor
{
	double _secondaryRadiusScale = 1.0;

	double get secondaryRadiusScale
	{
		return _secondaryRadiusScale;
	}

	void copyRadialGradient(RadialGradientColor node, Actor resetActor)
	{
		copyGradient(node, resetActor);
		_secondaryRadiusScale = node._secondaryRadiusScale;
	}

	static RadialGradientColor read(Actor actor, BinaryReader reader, RadialGradientColor component)
	{
		GradientColor.read(actor, reader, component);

		component._secondaryRadiusScale = reader.readFloat32();
		
		return component;
	}
}

class RadialGradientFill extends RadialGradientColor
{
	FillRule _fillRule = FillRule.EvenOdd;

	ActorComponent makeInstance(Actor resetActor)
	{
		RadialGradientFill instanceEvent = new RadialGradientFill();
		instanceEvent.copyRadialFill(this, resetActor);
		return instanceEvent;
	}

	void copyRadialFill(RadialGradientFill node, Actor resetActor)
	{
		copyRadialGradient(node, resetActor);
		_fillRule = node._fillRule;
	}

	static RadialGradientFill read(Actor actor, BinaryReader reader, RadialGradientFill component)
	{
		if(component == null)
		{
			component = new RadialGradientFill();
		}
		RadialGradientColor.read(actor, reader, component);
		component._fillRule = fillRuleLookup[reader.readUint8()];	
		return component;
	}
}

class RadialGradientStroke extends RadialGradientColor
{
	double _width = 1.0;
	double get width
	{
		return _width;
	}
	
	ActorComponent makeInstance(Actor resetActor)
	{
		RadialGradientStroke instanceEvent = new RadialGradientStroke();
		instanceEvent.copyRadialStroke(this, resetActor);
		return instanceEvent;
	}

	void copyRadialStroke(RadialGradientStroke node, Actor resetActor)
	{
		copyRadialGradient(node, resetActor);
		_width = node._width;
	}

	static RadialGradientStroke read(Actor actor, BinaryReader reader, RadialGradientStroke component)
	{
		if(component == null)
		{
			component = new RadialGradientStroke();
		}
		RadialGradientColor.read(actor, reader, component);
		component._width = reader.readFloat32();
		return component;
	}
}