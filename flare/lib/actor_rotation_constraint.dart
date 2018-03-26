import "actor_targeted_constraint.dart";
import "actor_node.dart";
import "actor_component.dart";
import "actor.dart";
import "binary_reader.dart";
import "math/transform_components.dart";
import "math/mat2d.dart";
import "dart:math";
import "transform_space.dart";

class ActorRotationConstraint extends ActorTargetedConstraint
{
	static const double PI2 = PI*2.0;
	
	bool _copy = false;
	double _scale = 1.0;
	bool _enableMin = false;
	bool _enableMax = false;
	double _max = 0.0;
	double _min = 0.0;
	bool _offset = false;
	int _sourceSpace = TransformSpace.World;
	int _destSpace = TransformSpace.World;
	int _minMaxSpace = TransformSpace.World;
	TransformComponents _componentsA = new TransformComponents();
	TransformComponents _componentsB = new TransformComponents();

	static ActorRotationConstraint read(Actor actor, BinaryReader reader, ActorRotationConstraint component)
	{
		if(component == null)
		{
			component = new ActorRotationConstraint();
		}
		ActorTargetedConstraint.read(actor, reader, component);
		// component._invertDirection = reader.readUint8() == 1;
			
		// int numInfluencedBones = reader.readUint8();
		// if(numInfluencedBones > 0)
		// {
		// 	component._influencedBones = new List<InfluencedBone>(numInfluencedBones);

		// 	for(int i = 0; i < numInfluencedBones; i++)
		// 	{
		// 		InfluencedBone ib = new InfluencedBone();
		// 		ib.boneIdx = reader.readUint16();
		// 		component._influencedBones[i] = ib;
		// 	}
		// }

		if((component._copy = reader.readUint8() == 1))
		{
			component._scale = reader.readFloat32();
		}
		if((component._enableMin = reader.readUint8() == 1))
		{
			component._min = reader.readFloat32();
		}
		if((component._enableMax = reader.readUint8() == 1))
		{
			component._max = reader.readFloat32();
		}

		component._offset = reader.readUint8() == 1;
		component._sourceSpace = reader.readUint8();
		component._destSpace = reader.readUint8();
		component._minMaxSpace = reader.readUint8();
		
		return component;
	}

	void constrain(ActorNode node)
	{
		ActorNode target = this.target;
		ActorNode grandParent = parent.parent;

		Mat2D transformA = parent.worldTransform;
		Mat2D transformB = new Mat2D();
		Mat2D.decompose(transformA, _componentsA);
		if(target == null)
		{
			Mat2D.copy(transformB, transformA);
			_componentsB[0] = _componentsA[0];
			_componentsB[1] = _componentsA[1];
			_componentsB[2] = _componentsA[2];
			_componentsB[3] = _componentsA[3];
			_componentsB[4] = _componentsA[4];
			_componentsB[5] = _componentsA[5];
		}
		else
		{
			Mat2D.copy(transformB, target.worldTransform);
			if(_sourceSpace == TransformSpace.Local)
			{
				ActorNode sourceGrandParent = target.parent;
				if(sourceGrandParent != null)
				{
					Mat2D inverse = new Mat2D();
					if(!Mat2D.invert(inverse, sourceGrandParent.worldTransform))
					{
						return;
					}
					Mat2D.multiply(transformB, inverse, transformB);
				}
			}
			Mat2D.decompose(transformB, _componentsB);

			if(!_copy)
			{
				_componentsB.rotation = _destSpace == TransformSpace.Local ? 1.0 : _componentsA.rotation;
			}
			else
			{
				_componentsB.rotation *= _scale;	
				if(_offset)
				{
					_componentsB.rotation += parent.rotation;
				}
			}

			if(_destSpace == TransformSpace.Local)
			{
				// Destination space is in parent transform coordinates.
				// Recompose the parent local transform and get it in world, then decompose the world for interpolation.
				if(grandParent != null)
				{
					Mat2D.compose(transformB, _componentsB);
					Mat2D.multiply(transformB, grandParent.worldTransform, transformB);
					Mat2D.decompose(transformB, _componentsB);
				}
			}
		}
		
		bool clampLocal = _minMaxSpace == TransformSpace.Local && grandParent != null;
		if(clampLocal)
		{
			// Apply min max in local space, so transform to local coordinates first.
			Mat2D.compose(transformB, _componentsB);
			Mat2D inverse = new Mat2D();
			if(!Mat2D.invert(inverse, grandParent.worldTransform))
			{
				return;
			}
			Mat2D.multiply(transformB, inverse, transformB);
			Mat2D.decompose(transformB, _componentsB);
		}
		if(_enableMax && _componentsB.rotation > _max)
		{
			_componentsB.rotation = _max;	
		}
		if(_enableMin && _componentsB.rotation < _min)
		{
			_componentsB.rotation = _min;	
		}
		if(clampLocal)
		{
			// Transform back to world.
			Mat2D.compose(transformB, _componentsB);
			Mat2D.multiply(transformB, grandParent.worldTransform, transformB);
			Mat2D.decompose(transformB, _componentsB);
		}

		double angleA = _componentsA.rotation%PI2;
		double angleB = _componentsB.rotation%PI2;
		double diff = angleB - angleA;
		
		if(diff > PI)
		{
			diff -= PI2;
		}
		else if(diff < -PI)
		{
			diff += PI2;
		}
		_componentsB.rotation = _componentsA.rotation + diff * strength;
		_componentsB.x = _componentsA.x;
		_componentsB.y = _componentsA.y;
		_componentsB.scaleX = _componentsA.scaleX;
		_componentsB.scaleY = _componentsA.scaleY;
		_componentsB.skew = _componentsA.skew;

		Mat2D.compose(parent.worldTransform, _componentsB);
	}
	
	ActorComponent makeInstance(Actor resetActor)
	{
		ActorRotationConstraint instance = new ActorRotationConstraint();
		instance.copyRotationConstraint(this, resetActor);
		return instance;
	}

	void copyRotationConstraint(ActorRotationConstraint node, Actor resetActor)
	{
		copyComponent(node, resetActor);

		_copy = node._copy;
		_scale = node._scale;
		_enableMin = node._enableMin;
		_enableMax = node._enableMax;
		_min = node._min;
		_max = node._max;

		_offset = node._offset;
		_sourceSpace = node._sourceSpace;
		_destSpace = node._destSpace;
		_minMaxSpace = node._minMaxSpace;
	}
	
	void update(int dirt) {}
	void completeResolve() {}
}