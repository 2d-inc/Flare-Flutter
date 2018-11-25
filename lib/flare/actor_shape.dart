import "actor_color.dart";
import "actor_component.dart";
import "actor_node.dart";
import "actor_drawable.dart";
import "actor_artboard.dart";
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

	int _drawOrder;
	@override
	int get drawOrder => _drawOrder;

	set drawOrder(int value)
	{
		if(_drawOrder == value)
		{
			return;
		}
		_drawOrder = value;
		artboard.markDrawOrderDirty();
	}

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

	void update(int dirt)
	{
		super.update(dirt);
		invalidateShape();
	}

	static ActorShape read(ActorArtboard artboard, StreamReader reader, ActorShape component)
	{
		if(component == null)
		{
			component = new ActorShape();
		}

		ActorNode.read(artboard, reader, component);

		component._isHidden = !reader.readBool("isVisible");
		/*blendMode*/ reader.readUint8("blendMode");
		component.drawOrder = reader.readUint16("drawOrder");
		return component;
	}

	ActorComponent makeInstance(ActorArtboard resetArtboard)
	{
		ActorShape instanceEvent = new ActorShape();
		instanceEvent.copyShape(this, resetArtboard);
		return instanceEvent;
	}

	void copyShape(ActorShape node, ActorArtboard resetArtboard)
	{
		copyNode(node, resetArtboard);
		drawOrder = node.drawOrder;
		_isHidden = node._isHidden;
	}

	AABB computeAABB()
	{
		AABB aabb;
		List<ActorClip> clippers = allClips;
		if(clippers != null)
		{
			for(ActorClip clip in clippers)
			{
				clip.node.all((ActorNode node)
				{
					if(node is ActorShape)
					{
						AABB bounds = node.computeAABB();
						if(bounds == null)
						{
							return;
						}
						if(aabb == null)
						{
							aabb = bounds;
						}
						else
						{
							if(bounds[0] < aabb[0])
							{
								aabb[0] = bounds[0];
							}
							if(bounds[1] < aabb[1])
							{
								aabb[1] = bounds[1];
							}
							if(bounds[2] > aabb[2])
							{
								aabb[2] = bounds[2];
							}
							if(bounds[3] > aabb[3])
							{
								aabb[3] = bounds[3];
							}
						}
					}
				});
			}
			if(aabb != null)
			{
				//print("AA $aabb");
				return aabb;
			}
		}

		for(ActorNode node in children)
		{
			ActorBasePath path = node as ActorBasePath;
			if(path == null)
			{
				continue;
			}
			// This is the axis aligned bounding box in the space of the parent (this case our shape).
			AABB pathAABB = path.getPathAABB();

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
