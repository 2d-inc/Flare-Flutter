import "dart:typed_data";
import "actor_path.dart";
import "actor_skinnable.dart";
import "actor.dart";
import "actor_component.dart";
import "math/mat2d.dart";
import "actor_constraint.dart";

class ActorSkin extends ActorComponent
{
	Float32List _boneMatrices;
	Float32List get boneMatrices => _boneMatrices;

	@override
	void onDirty(int dirt) 
	{
		// Intentionally empty. Doesn't throw dirt around.
	}

	@override
	void update(int dirt) 
	{
		ActorPath path = parent as ActorPath;
		if(path == null)
		{
			return;
		}

		if(path.isConnectedToBones)
		{
			List<SkinnedBone> connectedBones = path.connectedBones;
			int length = (connectedBones.length+1) * 6;
			if(_boneMatrices == null || _boneMatrices.length != length)
			{
				_boneMatrices = new Float32List(length);
				// First bone transform is always identity.
				_boneMatrices[0] = 1;
				_boneMatrices[1] = 0;
				_boneMatrices[2] = 0;
				_boneMatrices[3] = 1;
				_boneMatrices[4] = 0;
				_boneMatrices[5] = 0;
			}

			int bidx = 6; // Start after first identity.

			Mat2D mat = new Mat2D();

			for(SkinnedBone cb in connectedBones)
			{
				if(cb.node == null)
				{
					_boneMatrices[bidx++] = 1;
					_boneMatrices[bidx++] = 0;
					_boneMatrices[bidx++] = 0;
					_boneMatrices[bidx++] = 1;
					_boneMatrices[bidx++] = 0;
					_boneMatrices[bidx++] = 0;
					continue;
				}

				Mat2D.multiply(mat, cb.node.worldTransform, cb.inverseBind);

				_boneMatrices[bidx++] = mat[0];
				_boneMatrices[bidx++] = mat[1];
				_boneMatrices[bidx++] = mat[2];
				_boneMatrices[bidx++] = mat[3];
				_boneMatrices[bidx++] = mat[4];
				_boneMatrices[bidx++] = mat[5];
			}
		}

		path.markPathDirty();
	}

	@override
	void completeResolve() 
	{
		ActorPath path = parent as ActorPath;
		if(path == null)
		{
			return;
		}
		path.skin = this;
		actor.addDependency(this, path);
		if(path.isConnectedToBones)
		{
			List<SkinnedBone> connectedBones = path.connectedBones;
			for(SkinnedBone skinnedBone in connectedBones)
			{
				actor.addDependency(this, skinnedBone.node);
				List<ActorConstraint> constraints = skinnedBone.node.allConstraints;
							
				if(constraints != null)
				{
					for(ActorConstraint constraint in constraints)
					{
						actor.addDependency(this, constraint);
					}
				}
			}
		}
	}

	@override
	ActorComponent makeInstance(Actor resetActor) 
	{
		ActorSkin instance = new ActorSkin();
		instance.copyComponent(this, resetActor);
		return instance;	
	}
}