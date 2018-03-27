import "actor_component.dart";
import "actor_node.dart";
import "actor_drawable.dart";
import "actor.dart";
import "binary_reader.dart";
import "dart:typed_data";
import "actor_path.dart";
import "dart:math";
import "math/mat2d.dart";
import "math/vec2d.dart";

class ActorShape extends ActorDrawable
{
	bool _isHidden;

	bool get isHidden
	{
		return _isHidden;
	}

	bool get doesDraw
	{
		return !_isHidden && !this.renderCollapsed;
	}

	static ActorShape read(Actor actor, BinaryReader reader, ActorShape component)
	{
		if(component == null)
		{
			component = new ActorShape();
		}

		ActorNode.read(actor, reader, component);

		component._isHidden = reader.readUint8() == 0;
		/*blendMode*/ reader.readUint8();
		component.drawOrder = reader.readUint16();
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
		copyDrawable(node, resetActor);
		_isHidden = node._isHidden;
	}

	Float32List computeAABB()
	{
		Float32List aabb;
		for(ActorPath path in children)
		{
			// if(path.constructor !== ActorPath)
			// {
			// 	continue;
			// }

			// This is the axis aligned bounding box in the space of the parent (this case our shape).
			Float32List pathAABB = path.getPathAABB();

			if(aabb = null)
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

		double minX = double.MAX_FINITE;
		double minY = double.MAX_FINITE;
		double maxX = -double.MAX_FINITE;
		double maxY = -double.MAX_FINITE;

		if(aabb == null)
		{
			return new Float32List.fromList([minX, minY, maxX, maxY]);
		}
		Mat2D world = worldTransform;


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

		return new Float32List.fromList([minX, minY, maxX, maxY]);
	}
}
