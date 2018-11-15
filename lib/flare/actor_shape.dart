import "actor_color.dart";
import "actor_component.dart";
import "actor_node.dart";
import "actor_drawable.dart";
import "actor.dart";
import "stream_reader.dart";
import "actor_path.dart";
import "dart:math";
import "math/mat2d.dart";
import "math/vec2d.dart";
import "math/aabb.dart";

class ActorShape extends ActorNode implements ActorDrawable
{
	@override
	int drawIndex;

	@override
	int drawOrder;

	bool _isHidden;
	List<ActorStroke> _strokes;

	bool get isHidden
	{
		return _isHidden;
	}

	bool get doesDraw
	{
		return !_isHidden && !this.renderCollapsed;
	}

	static ActorShape read(Actor actor, StreamReader reader, ActorShape component)
	{
		if(component == null)
		{
			component = new ActorShape();
		}

		ActorNode.read(actor, reader, component);

		component._isHidden = !reader.readBool("isVisible");
		/*blendMode*/ reader.readUint8("blendMode");
		component.drawOrder = reader.readUint16("drawOrder");
		return component;
	}

	ActorComponent makeInstance(Actor resetActor)
	{
		ActorShape instanceEvent = new ActorShape();
		instanceEvent.copyShape(this, resetActor);
		return instanceEvent;
	}

	void copyShape(ActorShape node, Actor resetActor)
	{
		copyNode(node, resetActor);
		drawOrder = node.drawOrder;
		_isHidden = node._isHidden;
	}

	AABB computeAABB()
	{
		AABB aabb;

		for(ActorNode node in children)
		{
			ActorBasePath path = node as ActorBasePath;
			if(path == null)
			{
				continue;
			}
			// This is the axis aligned bounding box in the space of the parent (this case our shape).
			AABB pathAABB = path.getPathOBB();

			if(aabb == null)
			{
				aabb = pathAABB;
			}
			else
			{
				// Combine.
				aabb[0] = min(aabb[0], pathAABB[0]);
				aabb[1] = min(aabb[1], pathAABB[1]);

				aabb[2] = max(aabb[2], pathAABB[2]);
				aabb[3] = max(aabb[3], pathAABB[3]);
			}
		}

		double minX = double.maxFinite;
		double minY = double.maxFinite;
		double maxX = -double.maxFinite;
		double maxY = -double.maxFinite;

		if(aabb == null)
		{
			return new AABB.fromValues(minX, minY, maxX, maxY);
		}
		Mat2D world = worldTransform;

		if(_strokes != null)
		{
			double maxStroke = 0;
			for(ActorStroke stroke in _strokes)
			{
				if(stroke.width > maxStroke)
				{
					maxStroke = stroke.width;
				}
			}
			double padStroke = maxStroke/2.0;
			aabb[0] -= padStroke;
			aabb[2] += padStroke;
			aabb[1] -= padStroke;
			aabb[3] += padStroke;
		}

		List<Vec2D> points = [
			new Vec2D.fromValues(aabb[0], aabb[1]),
			new Vec2D.fromValues(aabb[2], aabb[1]),
			new Vec2D.fromValues(aabb[2], aabb[3]),
			new Vec2D.fromValues(aabb[0], aabb[3])
		];
		for(var i = 0; i < points.length; i++)
		{
			Vec2D pt = points[i];
			Vec2D wp = Vec2D.transformMat2D(pt, pt, world);
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
		return new AABB.fromValues(minX, minY, maxX, maxY);
	}

	void addStroke(ActorStroke stroke) 
	{
		if(_strokes == null)
		{
			_strokes = new List<ActorStroke>();
		}
		_strokes.add(stroke);
	}
}
