import '../actor_drawable.dart';
import "../stream_reader.dart";
import "../actor_component.dart";
import "../actor_node.dart";
import "../actor_bone_base.dart";
import "../actor_constraint.dart";
import "../actor_image.dart";
import "../actor_artboard.dart";
import "../actor_node_solo.dart";
import "../actor_star.dart";
import "../actor_rectangle.dart";
import "../math/mat2d.dart";
import "./interpolation/interpolator.dart";
import "./interpolation/hold.dart";
import "./interpolation/linear.dart";
import "./interpolation/cubic.dart";
import "dart:collection";
import "dart:typed_data";
import "../actor_path.dart";
import "../path_point.dart";
import "../actor_color.dart";

enum InterpolationTypes
{
	Hold,
	Linear,
	Cubic
}

HashMap<int,InterpolationTypes> interpolationTypesLookup = new HashMap<int,InterpolationTypes>.fromIterables([0,1,2], [InterpolationTypes.Hold, InterpolationTypes.Linear, InterpolationTypes.Cubic]);

abstract class KeyFrame
{
	double _time;

	double get time
	{
		return _time;
	}

	static bool read(StreamReader reader, KeyFrame frame)
	{
		frame._time = reader.readFloat64("time");

		return true;
	}

	void setNext(KeyFrame frame);
	void applyInterpolation(ActorComponent component, double time, KeyFrame toFrame, double mix);
	void apply(ActorComponent component, double mix);
}

abstract class KeyFrameWithInterpolation extends KeyFrame
{
	Interpolator _interpolator;

	Interpolator get interpolator
	{
		return _interpolator;
	}

	static bool read(StreamReader reader, KeyFrameWithInterpolation frame)
	{
		if(!KeyFrame.read(reader, frame))
		{
			return false;
		}
		int type = reader.readUint8("interpolatorType");
		
		InterpolationTypes actualType = interpolationTypesLookup[type];
		if(actualType == null)
		{
			actualType = InterpolationTypes.Linear;
		}
		
		switch(actualType)
		{
			case InterpolationTypes.Hold:
				frame._interpolator = HoldInterpolator.instance;
				break;
			case InterpolationTypes.Linear:
				frame._interpolator = LinearInterpolator.instance;
				break;
			case InterpolationTypes.Cubic:
			{
				CubicInterpolator interpolator = new CubicInterpolator();
				if(interpolator.read(reader))
				{
					frame._interpolator = interpolator;
				}
				break;
			}
			default:
				frame._interpolator = null;
		}
		return true;
	}

	void setNext(KeyFrame frame)
	{
		// Null out the interpolator if the next frame doesn't validate.
		// if(_interpolator != null && !_interpolator.setNextFrame(this, frame))
		// {
		// 	_interpolator = null;
		// }
	}
}

abstract class KeyFrameNumeric extends KeyFrameWithInterpolation
{
	double _value;

	double get value
	{
		return _value;
	}

	static bool read(StreamReader reader, KeyFrameNumeric frame)
	{
		if(!KeyFrameWithInterpolation.read(reader, frame))
		{
			return false;
		}
		frame._value = reader.readFloat32("value");
		/*if(frame._interpolator != null)
		{
			// TODO: in the future, this could also be a progression curve.
			ValueTimeCurveInterpolator vtci = frame._interpolator as ValueTimeCurveInterpolator;
			if(vtci != null)
			{
			vtci.SetKeyFrameValue(m_Value);
			}
		}*/
		return true;
	}

	void applyInterpolation(ActorComponent component, double time, KeyFrame toFrame, double mix)
	{
		KeyFrameNumeric to = toFrame as KeyFrameNumeric;
		double f = (time - _time)/(to._time-_time);
		if(_interpolator != null)
		{
			f = _interpolator.getEasedMix(f);
		}
		setValue(component, _value * (1.0-f) + to._value * f, mix);
	}
	
	void apply(ActorComponent component, double mix)
	{
		setValue(component, _value, mix);
	}

	void setValue(ActorComponent component, double value, double mix);
}

abstract class KeyFrameInt extends KeyFrameWithInterpolation
{
	double _value;

	double get value
	{
		return _value;
	}

	static bool read(StreamReader reader, KeyFrameInt frame)
	{
		if(!KeyFrameWithInterpolation.read(reader, frame))
		{
			return false;
		}
		frame._value = reader.readInt32("value").toDouble();
		return true;
	}

	void applyInterpolation(ActorComponent component, double time, KeyFrame toFrame, double mix)
	{
		KeyFrameNumeric to = toFrame as KeyFrameNumeric;
		double f = (time - _time)/(to._time-_time);
		if(_interpolator != null)
		{
			f = _interpolator.getEasedMix(f);
		}
		setValue(component, _value * (1.0-f) + to._value * f, mix);
	}
	
	void apply(ActorComponent component, double mix)
	{
		setValue(component, _value, mix);
	}

	void setValue(ActorComponent component, double value, double mix);
}

class KeyFrameIntProperty extends KeyFrameInt
{
	static KeyFrame read(StreamReader reader, ActorComponent component)
	{
		KeyFrameIntProperty frame = new KeyFrameIntProperty();
		if(KeyFrameInt.read(reader, frame))
		{
			return frame;
		}
		return null;
	}

	void setValue(ActorComponent component, double value, double mix)
	{
		// TODO
		//CustomIntProperty node = component as CustomIntProperty;
		//node.value = (node.value * (1.0 - mix) + value * mix).round();
	}
}

class KeyFrameFloatProperty extends KeyFrameNumeric
{
	static KeyFrame read(StreamReader reader, ActorComponent component)
	{
		KeyFrameFloatProperty frame = new KeyFrameFloatProperty();
		if(KeyFrameNumeric.read(reader, frame))
		{
			return frame;
		}
		return null;
	}

	void setValue(ActorComponent component, double value, double mix)
	{
		// TODO
		// CustomFloatProperty node = component as CustomFloatProperty;
		// node.value = node.value * (1.0 - mix) + value * mix;
	}
}

class KeyFrameStringProperty extends KeyFrame
{
	String _value;
	static KeyFrame read(StreamReader reader, ActorComponent component)
	{
		KeyFrameStringProperty frame = new KeyFrameStringProperty();
		if(!KeyFrame.read(reader, frame))
		{
			return null;
		}
		frame._value = reader.readString("value");
		return frame;
	}

	void setNext(KeyFrame frame)
	{
		// Do nothing.
	}

	void applyInterpolation(ActorComponent component, double time, KeyFrame toFrame, double mix)
	{
		apply(component, mix);
	}

	void apply(ActorComponent component, double mix)
	{
		// CustomStringProperty prop = component as CustomStringProperty;
		// prop.value = _value;
	}
}

class KeyFrameBooleanProperty extends KeyFrame
{
	bool _value;
	static KeyFrame read(StreamReader reader, ActorComponent component)
	{
		KeyFrameBooleanProperty frame = new KeyFrameBooleanProperty();
		if(!KeyFrame.read(reader, frame))
		{
			return null;
		}
		frame._value = reader.readBool("value");
		return frame;
	}

	void setNext(KeyFrame frame)
	{
		// Do nothing.
	}

	void applyInterpolation(ActorComponent component, double time, KeyFrame toFrame, double mix)
	{
		apply(component, mix);
	}

	void apply(ActorComponent component, double mix)
	{
		// CustomBooleanProperty prop = component as CustomBooleanProperty;
		// prop.value = _value;
	}
}

class KeyFrameCollisionEnabledProperty extends KeyFrame
{
	bool _value;
	static KeyFrame read(StreamReader reader, ActorComponent component)
	{
		KeyFrameCollisionEnabledProperty frame = new KeyFrameCollisionEnabledProperty();
		if(!KeyFrame.read(reader, frame))
		{
			return null;
		}
		frame._value = reader.readBool("value");
		return frame;
	}

	void setNext(KeyFrame frame)
	{
		// Do nothing.
	}

	void applyInterpolation(ActorComponent component, double time, KeyFrame toFrame, double mix)
	{
		apply(component, mix);
	}

	void apply(ActorComponent component, double mix)
	{
		// ActorCollider collider = component as ActorCollider;
		// collider.isCollisionEnabled = _value;
	}
}


class KeyFramePosX extends KeyFrameNumeric
{
	static KeyFrame read(StreamReader reader, ActorComponent component)
	{
		KeyFramePosX frame = new KeyFramePosX();
		if(KeyFrameNumeric.read(reader, frame))
		{
			return frame;
		}
		return null;
	}

	void setValue(ActorComponent component, double value, double mix)
	{
		ActorNode node = component as ActorNode;
		node.x = node.x * (1.0 - mix) + value * mix;
	}
}

class KeyFramePosY extends KeyFrameNumeric
{
	static KeyFrame read(StreamReader reader, ActorComponent component)
	{
		KeyFramePosY frame = new KeyFramePosY();
		if(KeyFrameNumeric.read(reader, frame))
		{
			return frame;
		}
		return null;
	}

	void setValue(ActorComponent component, double value, double mix)
	{
		ActorNode node = component as ActorNode;
		node.y = node.y * (1.0 - mix) + value * mix;
	}
}

class KeyFrameScaleX extends KeyFrameNumeric
{
	static KeyFrame read(StreamReader reader, ActorComponent component)
	{
		KeyFrameScaleX frame = new KeyFrameScaleX();
		if(KeyFrameNumeric.read(reader, frame))
		{
			return frame;
		}
		return null;
	}

	void setValue(ActorComponent component, double value, double mix)
	{
		ActorNode node = component as ActorNode;
		node.scaleX = node.scaleX * (1.0 - mix) + value * mix;
	}
}

class KeyFrameScaleY extends KeyFrameNumeric
{
	static KeyFrame read(StreamReader reader, ActorComponent component)
	{
		KeyFrameScaleY frame = new KeyFrameScaleY();
		if(KeyFrameNumeric.read(reader, frame))
		{
			return frame;
		}
		return null;
	}

	void setValue(ActorComponent component, double value, double mix)
	{
		ActorNode node = component as ActorNode;
		node.scaleY = node.scaleY * (1.0 - mix) + value * mix;
	}
}

class KeyFrameRotation extends KeyFrameNumeric
{
	static KeyFrame read(StreamReader reader, ActorComponent component)
	{
		KeyFrameRotation frame = new KeyFrameRotation();
		if(KeyFrameNumeric.read(reader, frame))
		{
			return frame;
		}
		return null;
	}

	void setValue(ActorComponent component, double value, double mix)
	{
		ActorNode node = component as ActorNode;
		node.rotation = node.rotation * (1.0 - mix) + value * mix;
	}
}

class KeyFrameOpacity extends KeyFrameNumeric
{
	static KeyFrame read(StreamReader reader, ActorComponent component)
	{
		KeyFrameOpacity frame = new KeyFrameOpacity();
		if(KeyFrameNumeric.read(reader, frame))
		{
			return frame;
		}
		return null;
	}

	void setValue(ActorComponent component, double value, double mix)
	{
		ActorNode node = component as ActorNode;
		node.opacity = node.opacity * (1.0 - mix) + value * mix;
	}
}

class KeyFrameLength extends KeyFrameNumeric
{
	static KeyFrame read(StreamReader reader, ActorComponent component)
	{
		KeyFrameLength frame = new KeyFrameLength();
		if(KeyFrameNumeric.read(reader, frame))
		{
			return frame;
		}
		return null;
	}

	void setValue(ActorComponent component, double value, double mix)
	{
		ActorBoneBase bone = component as ActorBoneBase;
		if(bone == null)
		{
			return;
		}
		bone.length = bone.length * (1.0 - mix) + value * mix;
	}
}

class KeyFrameConstraintStrength extends KeyFrameNumeric
{
	static KeyFrame read(StreamReader reader, ActorComponent component)
	{
		KeyFrameConstraintStrength frame = new KeyFrameConstraintStrength();
		if(KeyFrameNumeric.read(reader, frame))
		{
			return frame;
		}
		return null;
	}

	void setValue(ActorComponent component, double value, double mix)
	{
		ActorConstraint constraint = component as ActorConstraint;
		constraint.strength = constraint.strength * (1.0 - mix) + value * mix;
	}
}

class DrawOrderIndex
{
	int componentIndex;
	int order;
}

class KeyFrameDrawOrder extends KeyFrame
{
	List<DrawOrderIndex> _orderedNodes;

	static KeyFrame read(StreamReader reader, ActorComponent component)
	{
		KeyFrameDrawOrder frame = new KeyFrameDrawOrder();
		if(!KeyFrame.read(reader, frame))
		{
			return null;
		}
        reader.openArray("drawOrder");
		int numOrderedNodes = reader.readUint16Length();
		frame._orderedNodes = new List<DrawOrderIndex>(numOrderedNodes);
		for(int i = 0; i < numOrderedNodes; i++)
		{
            reader.openObject("order");
			DrawOrderIndex drawOrder = new DrawOrderIndex();
			drawOrder.componentIndex = reader.readId("component");
			drawOrder.order = reader.readUint16("order");
            reader.closeObject();
			frame._orderedNodes[i] = drawOrder;
		}
        reader.closeArray();
		return frame;
	}

	void setNext(KeyFrame frame)
	{
		// Do nothing.
	}

	void applyInterpolation(ActorComponent component, double time, KeyFrame toFrame, double mix)
	{
		apply(component, mix);
	}

	void apply(ActorComponent component, double mix)
	{
		ActorArtboard artboard = component.artboard;

		for(DrawOrderIndex doi in _orderedNodes)
		{
			ActorDrawable drawable = artboard[doi.componentIndex] as ActorDrawable;
			if(drawable != null)
			{
				drawable.drawOrder = doi.order;
			}
		}
	}
}

class KeyFrameVertexDeform extends KeyFrameWithInterpolation
{
	Float32List _vertices;

	Float32List get vertices
	{
		return _vertices;
	}

	static KeyFrame read(StreamReader reader, ActorComponent component)
	{
		KeyFrameVertexDeform frame = new KeyFrameVertexDeform();
		if(!KeyFrameWithInterpolation.read(reader, frame))
		{
			return null;
		}

		ActorImage imageNode = component as ActorImage;
		frame._vertices = new Float32List(imageNode.vertexCount * 2);
		reader.readFloat32ArrayOffset(frame._vertices, frame._vertices.length, 0, "value");
		
		imageNode.doesAnimationVertexDeform = true;

		return frame;
	}

	void transformVertices(Mat2D wt)
	{
		int aiVertexCount = _vertices.length ~/ 2;
		Float32List fv = _vertices;

		int vidx = 0;
		for(int j = 0; j < aiVertexCount; j++)
		{
			double x = fv[vidx];
			double y = fv[vidx+1];

			fv[vidx] = wt[0] * x + wt[2] * y + wt[4];
			fv[vidx+1] = wt[1] * x + wt[3] * y + wt[5];

			vidx += 2;
		}
	}

	void setNext(KeyFrame frame)
	{
		// Do nothing.
	}

	void applyInterpolation(ActorComponent component, double time, KeyFrame toFrame, double mix)
	{
		ActorImage imageNode = component as ActorImage;
		Float32List wr = imageNode.animationDeformedVertices;
		Float32List to = (toFrame as KeyFrameVertexDeform)._vertices;
		int l = _vertices.length;

		double f = (time - _time)/(toFrame.time-_time);
		if(_interpolator != null)
		{
			f = _interpolator.getEasedMix(f);
		}

		double fi = 1.0 - f;
		if(mix == 1.0)
		{
			for(int i = 0; i < l; i++)
			{
				wr[i] = _vertices[i] * fi + to[i] * f;
			}
		}
		else
		{
			double mixi = 1.0 - mix;
			for(int i = 0; i < l; i++)
			{
				double v = _vertices[i] * fi + to[i] * f;

				wr[i] = wr[i] * mixi + v * mix;
			}
		}

		imageNode.isVertexDeformDirty = true;
	}
	
	void apply(ActorComponent component, double mix)
	{
		ActorImage imageNode = component as ActorImage;
		int l = _vertices.length;
		Float32List wr = imageNode.animationDeformedVertices;
		if(mix == 1.0)
		{
			for(int i = 0; i < l; i++)
			{
				wr[i] = _vertices[i];
			}
		}
		else
		{
			double mixi = 1.0 - mix;
			for(int i = 0; i < l; i++)
			{
				wr[i] = wr[i] * mixi + _vertices[i] * mix;
			}
		}

		imageNode.isVertexDeformDirty = true;
	}
}

class KeyFrameTrigger extends KeyFrame
{
	static KeyFrame read(StreamReader reader, ActorComponent component)
	{
		KeyFrameTrigger frame = new KeyFrameTrigger();
		if(!KeyFrame.read(reader, frame))
		{
			return null;
		}
		return frame;
	}

	void setNext(KeyFrame frame)
	{
		// Do nothing.
	}

	void applyInterpolation(ActorComponent component, double time, KeyFrame toFrame, double mix)
	{
	}

	void apply(ActorComponent component, double mix)
	{
	}
}


class KeyFrameActiveChild extends KeyFrame
{
	int _value;

	static KeyFrame read(StreamReader reader, ActorComponent component)
	{
		KeyFrameActiveChild frame = new KeyFrameActiveChild();
		if (!KeyFrame.read(reader, frame))
		{
			return null;
		}
		frame._value = reader.readFloat32("value").toInt();
		return frame;
	}

	void setNext(KeyFrame frame)
	{
		// No Interpolation
	}

	void applyInterpolation(ActorComponent component, double time, KeyFrame toFrame, double mix)
	{
		apply(component, mix);
	}

	void apply(ActorComponent component, double mix)
	{
		ActorNodeSolo soloNode = component as ActorNodeSolo;
		soloNode.activeChildIndex = _value;
	}
}

class KeyFrameSequence extends KeyFrameNumeric
{
	static KeyFrame read(StreamReader reader, ActorComponent component)
	{
		KeyFrameSequence frame = new KeyFrameSequence();
		if(KeyFrameNumeric.read(reader, frame))
		{
			return frame;
		}
		return null;
	}

	void setValue(ActorComponent component, double value, double mix)
	{
		ActorImage node = component as ActorImage;
		 int frameIndex = value.floor() % node.sequenceFrames.length;
		 if(frameIndex < 0)
		 {
				frameIndex += node.sequenceFrames.length;
		 }
		 node.sequenceFrame = frameIndex;
	}
}

class KeyFrameFillColor extends KeyFrameWithInterpolation
{
	Float32List _value;

	Float32List get value
	{
		return _value;
	}

	static KeyFrame read(StreamReader reader, ActorComponent component)
	{
		KeyFrameFillColor frame = new KeyFrameFillColor();
		if(!KeyFrameWithInterpolation.read(reader, frame))
		{
			return null;
		}

		frame._value = new Float32List(4);
		reader.readFloat32ArrayOffset(frame._value, 4, 0, "value");
		return frame;
	}

	void setNext(KeyFrame frame)
	{
		// Do nothing.
	}

	void applyInterpolation(ActorComponent component, double time, KeyFrame toFrame, double mix)
	{
		ActorColor ac = component as ActorColor;
		Float32List wr = ac.color;
		Float32List to = (toFrame as KeyFrameFillColor)._value;
		int l = _value.length;

		double f = (time - _time)/(toFrame.time-_time);
		double fi = 1.0 - f;
		if(mix == 1.0)
		{
			for(int i = 0; i < l; i++)
			{
				wr[i] = _value[i] * fi + to[i] * f;
			}
		}
		else
		{
			double mixi = 1.0 - mix;
			for(int i = 0; i < l; i++)
			{
				double v = _value[i] * fi + to[i] * f;

				wr[i] = wr[i] * mixi + v * mix;
			}
		}

		//path.markVertexDeformDirty();
	}
	
	void apply(ActorComponent component, double mix)
	{
		ActorColor ac = component as ActorColor;
		int l = _value.length;
		Float32List wr = ac.color;
		if(mix == 1.0)
		{
			for(int i = 0; i < l; i++)
			{
				wr[i] = _value[i];
			}
		}
		else
		{
			double mixi = 1.0 - mix;
			for(int i = 0; i < l; i++)
			{
				wr[i] = wr[i] * mixi + _value[i] * mix;
			}
		}
	}
}

class KeyFramePathVertices extends KeyFrameWithInterpolation
{
	Float32List _vertices;

	Float32List get vertices
	{
		return _vertices;
	}

	static KeyFrame read(StreamReader reader, ActorComponent component)
	{
		KeyFramePathVertices frame = new KeyFramePathVertices();
		if(!KeyFrameWithInterpolation.read(reader, frame))
		{
			return null;
		}


		ActorPath pathNode = component as ActorPath;

		int length = pathNode.points.fold<int>(0, (int previous, PathPoint point)
		{
			return previous + 2 + (point.pointType == PointType.Straight ? 1 : 4);
		});
		frame._vertices = new Float32List(length);
		int readIdx = 0;
		for(PathPoint point in pathNode.points)
		{
			reader.readFloat32ArrayOffset(frame._vertices, 2, readIdx, "translation");
			if(point.pointType == PointType.Straight)
			{
				// radius
				reader.readFloat32ArrayOffset(frame._vertices, 1, readIdx+2, "radius");

				readIdx += 3;
			}
			else
			{
				// in/out
				reader.readFloat32ArrayOffset(frame._vertices, 2, readIdx+2, "inValue");
				reader.readFloat32ArrayOffset(frame._vertices, 2, readIdx+4, "outValue");
				readIdx += 6;
			}
		}

		pathNode.vertexDeform = new Float32List.fromList(frame._vertices);
		return frame;
	}

	void setNext(KeyFrame frame)
	{
		// Do nothing.
	}

	void applyInterpolation(ActorComponent component, double time, KeyFrame toFrame, double mix)
	{
		ActorPath path = component as ActorPath;
		Float32List wr = path.vertexDeform;
		Float32List to = (toFrame as KeyFramePathVertices)._vertices;
		int l = _vertices.length;

		double f = (time - _time)/(toFrame.time-_time);
		double fi = 1.0 - f;
		if(mix == 1.0)
		{
			for(int i = 0; i < l; i++)
			{
				wr[i] = _vertices[i] * fi + to[i] * f;
			}
		}
		else
		{
			double mixi = 1.0 - mix;
			for(int i = 0; i < l; i++)
			{
				double v = _vertices[i] * fi + to[i] * f;

				wr[i] = wr[i] * mixi + v * mix;
			}
		}

		path.markVertexDeformDirty();
	}
	
	void apply(ActorComponent component, double mix)
	{
		ActorPath path = component as ActorPath;
		int l = _vertices.length;
		Float32List wr = path.vertexDeform;
		if(mix == 1.0)
		{
			for(int i = 0; i < l; i++)
			{
				wr[i] = _vertices[i];
			}
		}
		else
		{
			double mixi = 1.0 - mix;
			for(int i = 0; i < l; i++)
			{
				wr[i] = wr[i] * mixi + _vertices[i] * mix;
			}
		}

		path.markVertexDeformDirty();
	}
}

class KeyFrameFillOpacity extends KeyFrameNumeric
{
	static KeyFrame read(StreamReader reader, ActorComponent component)
	{
		KeyFrameFillOpacity frame = new KeyFrameFillOpacity();
		if(KeyFrameNumeric.read(reader, frame))
		{
			return frame;
		}
		return null;
	}

	void setValue(ActorComponent component, double value, double mix)
	{
		// GradientFill node = component as GradientFill;
		ActorPaint node = component as ActorPaint;
		node.opacity = node.opacity * (1.0 - mix) + value * mix;
	}
}

class KeyFrameStrokeColor extends KeyFrameWithInterpolation
{
    Float32List _value;

	Float32List get value
	{
		return _value;
	}

	static KeyFrame read(StreamReader reader, ActorComponent component)
	{
		KeyFrameStrokeColor frame = new KeyFrameStrokeColor();
		if(!KeyFrameWithInterpolation.read(reader, frame))
		{
			return null;
		}
		frame._value = new Float32List(4);
		reader.readFloat32ArrayOffset(frame._value, 4, 0, "value");
		return frame;
	}

    @override
    applyInterpolation(ActorComponent component, double time, KeyFrame toFrame, double mix)
    {
        ColorStroke cs = component as ColorStroke;
        Float32List wr = cs.color;
        Float32List to = (toFrame as KeyFrameStrokeColor)._value;
        int len = _value.length;

        double f = (time - _time)/(toFrame.time - _time);
        double fi = 1.0 - f;
        if(mix == 1.0)
        {
            for(int i = 0; i < len; i++)
            {
                wr[i] = _value[i] * fi + to[i] * f;
            }
        }
        else
		{
			double mixi = 1.0 - mix;
			for(int i = 0; i < len; i++)
			{
				double v = _value[i] * fi + to[i] * f;

				wr[i] = wr[i] * mixi + v * mix;
			}
		}
    }

    @override
    apply(ActorComponent component, double mix)
    {
        ColorStroke node = component as ColorStroke;
        Float32List wr = node.color;
        int len = wr.length;
        if(mix == 1.0)
        {
            for(int i = 0; i < len; i++)
            {
                wr[i] = _value[i];
            }
        }
        else
        {
            double mixi = 1.0 - mix;
            for(int i = 0; i < len; i++)
            {
				wr[i] = wr[i] * mixi + _value[i] * mix;
            }
        }
    }
}

class KeyFrameCornerRadius extends KeyFrameNumeric
{
    static KeyFrame read(StreamReader reader, ActorComponent component)
	{
		KeyFrameCornerRadius frame = new KeyFrameCornerRadius();
		if(KeyFrameNumeric.read(reader, frame))
		{
			return frame;
		}
		return null;
	}

	void setValue(ActorComponent component, double value, double mix)
	{
		ActorRectangle node = component as ActorRectangle;
		node.radius = node.radius * (1.0 - mix) + value * mix;
	}
}

class KeyFrameGradient extends KeyFrameWithInterpolation
{
    Float32List _value;
    get value => _value;

    static KeyFrame read(StreamReader reader, ActorComponent component)
	{
		KeyFrameGradient frame = new KeyFrameGradient();
		if(!KeyFrameWithInterpolation.read(reader, frame))
		{
			return null;
		}
        int len = reader.readUint16("length");
        frame._value = new Float32List(len);
		reader.readFloat32Array(frame._value, "value");
		return frame;
	}

	@override
    applyInterpolation(ActorComponent component, double time, KeyFrame toFrame, double mix)
    {
        GradientColor gradient = component as GradientColor;
        Float32List v = (toFrame as KeyFrameGradient)._value;
        
        double f = (time - _time)/(toFrame.time - _time);
        if(_interpolator != null)
        {
            f = _interpolator.getEasedMix(f);
        }
        double fi = 1.0 - f;

        int ridx = 0;
        int wi = 0;

        if(mix == 1.0)
        {
            gradient.start[0] = _value[ridx] * fi + v[ridx++] * f;
            gradient.start[1] = _value[ridx] * fi + v[ridx++] * f;
            gradient.end[0] = _value[ridx] * fi + v[ridx++] * f;
            gradient.end[1] = _value[ridx] * fi + v[ridx++] * f;

            while(ridx < v.length && wi < gradient.colorStops.length)
            {
                gradient.colorStops[wi++] = _value[ridx] * fi + v[ridx++] * f;
            }
        }
        else
		{
			double imix = 1.0 - mix;

            // Mix : first interpolate the KeyFrames, and then mix on top of the current value.
            double val = _value[ridx]*fi + v[ridx]*f;
            gradient.start[0] = gradient.start[0]*imix + val*mix;
            ridx++;

            val = _value[ridx]*fi + v[ridx]*f;
            gradient.start[1] = gradient.start[1]*imix + val*mix;
            ridx++;
            
            val = _value[ridx]*fi + v[ridx]*f;
            gradient.end[0] = gradient.end[0]*imix + val*mix;
            ridx++;
            
            val = _value[ridx]*fi + v[ridx]*f;
            gradient.end[1] = gradient.end[1]*imix + val*mix;
            ridx++;

			while(ridx < v.length && wi < gradient.colorStops.length)
            {
                val = _value[ridx]*fi + v[ridx]*f;
                gradient.colorStops[wi] = gradient.colorStops[wi]*imix + val*mix;
                
                ridx++; 
                wi++;
            }
		}
    }



    @override
    apply(ActorComponent component, double mix)
    {
        GradientColor gradient = component as GradientColor;
        
        int ridx = 0;
        int wi = 0;

        if(mix == 1.0)
        {
            gradient.start[0] = _value[ridx++];
            gradient.start[1] = _value[ridx++];
            gradient.end[0] = _value[ridx++];
            gradient.end[1] = _value[ridx++];

            while(ridx < _value.length && wi < gradient.colorStops.length)
            {
                gradient.colorStops[wi++] = _value[ridx++];
            }
        }
        else
        {
            double imix = 1.0 - mix;
            gradient.start[0] = gradient.start[0]*imix + _value[ridx++]*mix;
            gradient.start[1] = gradient.start[1]*imix + _value[ridx++]*mix;
            gradient.end[0] = gradient.end[0]*imix + _value[ridx++]*mix;
            gradient.end[1] = gradient.end[1]*imix + _value[ridx++]*mix;

            while(ridx < _value.length && wi < gradient.colorStops.length)
            {
                gradient.colorStops[wi] = gradient.colorStops[wi]*imix + _value[ridx++];
                wi++;
            }
        }
    }
}

class KeyFrameRadial extends KeyFrameWithInterpolation
{
    Float32List _value;
    get value => _value;

    static KeyFrame read(StreamReader reader, ActorComponent component)
	{
		KeyFrameRadial frame = new KeyFrameRadial();
		if(!KeyFrameWithInterpolation.read(reader, frame))
		{
			return null;
		}
        int len = reader.readUint16("length");
        frame._value = new Float32List(len);
		reader.readFloat32Array(frame._value, "value");
		return frame;
	}

	@override
    applyInterpolation(ActorComponent component, double time, KeyFrame toFrame, double mix)
    {
        RadialGradientColor radial = component as RadialGradientColor;
        Float32List v = (toFrame as KeyFrameRadial)._value;
        
        double f = (time - _time)/(toFrame.time - _time);
        if(_interpolator != null)
        {
            f = _interpolator.getEasedMix(f);
        }
        double fi = 1.0 - f;

        int ridx = 0;
        int wi = 0;

        if(mix == 1.0)
        {
            radial.secondaryRadiusScale = _value[ridx] * fi + v[ridx++] * f;
            radial.start[0] = _value[ridx] * fi + v[ridx++] * f;
            radial.start[1] = _value[ridx] * fi + v[ridx++] * f;
            radial.end[0] = _value[ridx] * fi + v[ridx++] * f;
            radial.end[1] = _value[ridx] * fi + v[ridx++] * f;

            while(ridx < v.length && wi < radial.colorStops.length)
            {
                radial.colorStops[wi++] = _value[ridx] * fi + v[ridx++] * f;
            }
        }
        else
		{
			double imix = 1.0 - mix;

            // Mix : first interpolate the KeyFrames, and then mix on top of the current value.
            double val = _value[ridx]*fi + v[ridx]*f;
            radial.secondaryRadiusScale = _value[ridx] * fi + v[ridx++] * f;
            val = _value[ridx]*fi + v[ridx]*f;
            radial.start[0] = _value[ridx++]*imix + val*mix;
            val = _value[ridx]*fi + v[ridx]*f;
            radial.start[1] = _value[ridx++]*imix + val*mix;
            val = _value[ridx]*fi + v[ridx]*f;
            radial.end[0] = _value[ridx++]*imix + val*mix;
            val = _value[ridx]*fi + v[ridx]*f;
            radial.end[1] = _value[ridx++]*imix + val*mix;

			while(ridx < v.length && wi < radial.colorStops.length)
            {
                val = _value[ridx]*fi + v[ridx]*f;
                radial.colorStops[wi] = radial.colorStops[wi]*imix + val*mix;
                
                ridx++; 
                wi++;
            }
		}
    }

    @override
    apply(ActorComponent component, double mix)
    {
        RadialGradientColor radial = component as RadialGradientColor;
        
        int ridx = 0;
        int wi = 0;

        if(mix == 1.0)
        {
            radial.secondaryRadiusScale = value[ridx++];
            radial.start[0] = _value[ridx++];
            radial.start[1] = _value[ridx++];
            radial.end[0] = _value[ridx++];
            radial.end[1] = _value[ridx++];

            while(ridx < _value.length && wi < radial.colorStops.length)
            {
                radial.colorStops[wi++] = _value[ridx++];
            }
        }
        else
        {
            double imix = 1.0 - mix;
            radial.secondaryRadiusScale = radial.secondaryRadiusScale*imix + value[ridx++]*mix;
            radial.start[0] = radial.start[0]*imix + _value[ridx++]*mix;
            radial.start[1] = radial.start[1]*imix + _value[ridx++]*mix;
            radial.end[0] = radial.end[0]*imix + _value[ridx++]*mix;
            radial.end[1] = radial.end[1]*imix + _value[ridx++]*mix;

            while(ridx < _value.length && wi < radial.colorStops.length)
            {
                radial.colorStops[wi] = radial.colorStops[wi]*imix + _value[ridx++];
                wi++;
            }
        }
    }
}

class KeyFrameShapeWidth extends KeyFrameNumeric
{
	static KeyFrame read(StreamReader reader, ActorComponent component)
	{
		KeyFrameShapeWidth frame = new KeyFrameShapeWidth();
		if(KeyFrameNumeric.read(reader, frame))
		{
			return frame;
		}
		return null;
	}

	void setValue(ActorComponent component, double value, double mix)
	{
		if(component == null) return;

        if(component is ActorProceduralPath)
        {
            component.width = component.width * (1.0 - mix) + value * mix;
        }
	}
}

class KeyFrameShapeHeight extends KeyFrameNumeric
{
	static KeyFrame read(StreamReader reader, ActorComponent component)
	{
		KeyFrameShapeHeight frame = new KeyFrameShapeHeight();
		if(KeyFrameNumeric.read(reader, frame))
		{
			return frame;
		}
		return null;
	}

	void setValue(ActorComponent component, double value, double mix)
	{
		if(component == null) return;

        if(component is ActorProceduralPath)
        {
            component.height = component.height * (1.0 - mix) + value * mix;
						//print("YEAHe ${component.name} ${component.height}");
        }
	}
}

class KeyFrameStrokeWidth extends KeyFrameNumeric
{
	static KeyFrame read(StreamReader reader, ActorComponent component)
	{
		KeyFrameStrokeWidth frame = new KeyFrameStrokeWidth();
		if(KeyFrameNumeric.read(reader, frame))
		{
			return frame;
		}
		return null;
	}

	void setValue(ActorComponent component, double value, double mix)
	{
		if(component == null) return;

        if(component is GradientStroke)
        {
            component.width = component.width * (1.0 - mix) + value * mix;
        }
        else if(component is RadialGradientStroke)
        {
            component.width = component.width * (1.0 - mix) + value * mix;
        }
        else if(component is ColorStroke)
        {
            component.width = component.width * (1.0 - mix) + value * mix;
        }
	}
}

class KeyFrameStrokeOpacity extends KeyFrameNumeric
{
	static KeyFrame read(StreamReader reader, ActorComponent component)
	{
		KeyFrameStrokeOpacity frame = new KeyFrameStrokeOpacity();
		if(KeyFrameNumeric.read(reader, frame))
		{
			return frame;
		}
		return null;
	}

	void setValue(ActorComponent component, double value, double mix)
	{
		if(component == null) return;

        if(component is GradientColor)
        {
            component.opacity = component.opacity * (1.0 - mix) + value * mix;
        }
        else if(component is ColorStroke)
        {
            component.opacity = component.opacity * (1.0 - mix) + value * mix;
        }
	}
}

class KeyFrameInnerRadius extends KeyFrameNumeric
{
	static KeyFrame read(StreamReader reader, ActorComponent component)
	{
		KeyFrameInnerRadius frame = new KeyFrameInnerRadius();
		if(KeyFrameNumeric.read(reader, frame))
		{
			return frame;
		}
		return null;
	}

	void setValue(ActorComponent component, double value, double mix)
	{
		if(component == null) return;

        ActorStar star = component as ActorStar;
        star.innerRadius = star.innerRadius * (1.0-mix) + value*mix;
	}
}