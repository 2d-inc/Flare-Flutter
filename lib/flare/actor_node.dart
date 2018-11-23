import "stream_reader.dart";
import "actor_artboard.dart";
import "math/mat2d.dart";
import "math/vec2d.dart";
import "actor_component.dart";
import "actor_constraint.dart";

typedef bool NodeWalkCallback(ActorNode node);

class ActorClip
{
	int clipIdx;
	ActorNode node;

	ActorClip(int idx)
	{
		clipIdx = idx;
	}
}

class ActorNode extends ActorComponent
{
	List<ActorNode> _children;
	//List<ActorNode> m_Dependents;
	Mat2D _transform = new Mat2D();
	Mat2D _worldTransform = new Mat2D();

	Vec2D _translation = new Vec2D();
	double _rotation = 0.0;
	Vec2D _scale = new Vec2D.fromValues(1.0, 1.0);
	double _opacity = 1.0;
	double _renderOpacity = 1.0;

	bool _overrideWorldTransform = false;
	bool _isCollapsedVisibility = false;

	bool _renderCollapsed = false;
	List<ActorClip> _clips;

	List<ActorConstraint> _constraints;
	List<ActorConstraint> _peerConstraints;

	static const int TransformDirty = 1<<0;
	static const int WorldTransformDirty = 1<<1;

	ActorNode();
	ActorNode.withArtboard(ActorArtboard artboard) : super.withArtboard(artboard);

	Mat2D get transform
	{
		return _transform;
	}

	List<ActorClip> get clips
	{
		return _clips;
	}

	Mat2D get worldTransformOverride
	{
		return _overrideWorldTransform ? _worldTransform : null;
	}

	set worldTransformOverride(Mat2D value)
	{
		if(value == null)
		{
			_overrideWorldTransform = false;
		}
		else
		{
			_overrideWorldTransform = true;
			Mat2D.copy(worldTransform, value);
		}
		markTransformDirty();
	}

	Mat2D get worldTransform
	{
		return _worldTransform;
	}

	// N.B. this should only be done if you really know what you're doing. Generally you want to manipulate the local translation, rotation, and scale of a Node.
	set worldTransform(Mat2D value)
	{
		Mat2D.copy(_worldTransform, value);
	}

	double get x
	{
		return _translation[0];
	}

	set x(double value)
	{
		if(_translation[0] == value)
		{
			return;
		}
		_translation[0] = value;
		markTransformDirty();
	}
	
	double get y
	{
		return _translation[1];
	}

	set y(double value)
	{
		if(_translation[1] == value)
		{
			return;
		}
		_translation[1] = value;
		markTransformDirty();
	}

	Vec2D get translation
	{
		return new Vec2D.clone(_translation);
	}

	set translation(Vec2D value)
	{
		Vec2D.copy(_translation, value);
		markTransformDirty();
	}
	
	double get rotation
	{
		return _rotation;
	}
	
	set rotation(double value)
	{
		if(_rotation == value)
		{
			return;
		}
		_rotation = value;
		markTransformDirty();
	}
	
	double get scaleX
	{
		return _scale[0];
	}
	
	set scaleX(double value)
	{
		if(_scale[0] == value)
		{
			return;
		}
		_scale[0] = value;
		markTransformDirty();
	}
	
	double get scaleY
	{
		return _scale[1];
	}
	
	set scaleY(double value)
	{
		if(_scale[1] == value)
		{
			return;
		}
		_scale[1] = value;
		markTransformDirty();
	}
	
	double get opacity
	{
		return _opacity;
	}

	set opacity(double value)
	{
		if(_opacity == value)
		{
			return;
		}
		_opacity = value;
		markTransformDirty();
	}

	double get renderOpacity
	{
		return _renderOpacity;
	}

	bool get renderCollapsed
	{
		return _renderCollapsed;
	}

	bool get collapsedVisibility
	{
		return _isCollapsedVisibility;
	}

	set collapsedVisibility(bool value)
	{
		if(_isCollapsedVisibility != value)
		{
			_isCollapsedVisibility = value;
			markTransformDirty();
		}
	}

	List<ActorClip> get allClips
	{
		// Find clips.
		List<ActorClip> all = null;
		ActorNode clipSearch = this;
		while(clipSearch != null)
		{
			if(clipSearch.clips != null)
			{
				if(all == null)
				{
					all = clipSearch.clips;
				}
				else
				{
					all += clipSearch.clips;
				}
			}
			clipSearch = clipSearch.parent;
		}

		return all;
	}

	void markTransformDirty()
	{
		if(artboard == null)
		{
			// Still loading?
			return;
		}
		if(!artboard.addDirt(this, TransformDirty, false))
		{
			return;
		}
		artboard.addDirt(this, WorldTransformDirty, true);
	}

	void updateTransform()
	{
		Mat2D.fromRotation(_transform, _rotation);
		_transform[4] = _translation[0];
		_transform[5] = _translation[1];
		Mat2D.scale(_transform, _transform, _scale);
	}

	Vec2D getWorldTranslation(Vec2D vec)
	{
		vec[0] = _worldTransform[4];
		vec[1] = _worldTransform[5];
		return vec;
	}

	void updateWorldTransform()
	{
		_renderOpacity = _opacity;
	
		if(parent != null)
		{
			_renderCollapsed = _isCollapsedVisibility || parent._renderCollapsed;
			_renderOpacity *= parent._renderOpacity;
			if(!_overrideWorldTransform)
			{
				Mat2D.multiply(_worldTransform, parent._worldTransform, _transform);
			}
		}
		else
		{
			Mat2D.copy(_worldTransform, _transform);
		}
	}

	static ActorNode read(ActorArtboard artboard, StreamReader reader, ActorNode node)
	{
		if(node == null)
		{
			node = new ActorNode();
		}
		ActorComponent.read(artboard, reader, node);
		reader.readFloat32ArrayOffset(node._translation.values, 2, 0, "translation");
		node._rotation = reader.readFloat32("rotation");
		reader.readFloat32ArrayOffset(node._scale.values, 2, 0, "scale");
		node._opacity = reader.readFloat32("opacity");
		node._isCollapsedVisibility = reader.readBool("isCollapsed");

        reader.openArray("clips");
		int clipCount = reader.readUint8Length();
		if(clipCount > 0)
		{
			node._clips = new List<ActorClip>(clipCount);
			for(int i = 0; i < clipCount; i++)
			{
				node._clips[i] = new ActorClip(reader.readId("clip"));
			}
		}
        reader.closeArray();
		return node;
	}

	void addChild(ActorNode node)
	{
		if(node.parent != null)
		{
			node.parent._children.remove(node);
		}
		node.parent = this;
		if(_children == null)
		{
			_children = new List<ActorNode>();
		}
		_children.add(node);
	}

	List<ActorNode> get children
	{
		return _children;
	}

	ActorComponent makeInstance(ActorArtboard resetArtboard)
	{
		ActorNode instanceNode = new ActorNode();
		instanceNode.copyNode(this, resetArtboard);
		return instanceNode;
	}

	void copyNode(ActorNode node, ActorArtboard resetArtboard)
	{
		copyComponent(node, resetArtboard);
		_transform = new Mat2D.clone(node._transform);
		_worldTransform = new Mat2D.clone(node._worldTransform);
		_translation = new Vec2D.clone(node._translation);
		_scale = new Vec2D.clone(node._scale);
		_rotation = node._rotation;
		_opacity = node._opacity;
		_renderOpacity = node._renderOpacity;
		_overrideWorldTransform = node._overrideWorldTransform;

		if(node._clips != null)
		{
			_clips = new List<ActorClip>(node._clips.length);
			for(int i = 0, l = node._clips.length; i < l; i++)
			{
				_clips[i] = new ActorClip(node._clips[i].clipIdx);
			}
		}
		else
		{
			_clips = null;
		}
	}

	void onDirty(int dirt)
	{

	}

	bool addConstraint(ActorConstraint constraint)
	{
		if(_constraints == null)
		{
			_constraints = new List<ActorConstraint>();
		}
		if(_constraints.contains(constraint))
		{
			return false;
		}
		_constraints.add(constraint);
		return true;
	}

	bool addPeerConstraint(ActorConstraint constraint)
	{
		if(_peerConstraints == null)
		{
			_peerConstraints = new List<ActorConstraint>();
		}
		if(_peerConstraints.contains(constraint))
		{
			return false;
		}
		_peerConstraints.add(constraint);
		return true;
	}

	List<ActorConstraint> get allConstraints => (_constraints == null ? _peerConstraints : _peerConstraints == null ? _constraints : _constraints + _peerConstraints) ?? <ActorConstraint>[];

	void update(int dirt)
	{
		if((dirt & TransformDirty) == TransformDirty)
		{
			updateTransform();
		}
		if((dirt & WorldTransformDirty) == WorldTransformDirty)
		{
			updateWorldTransform();
			if(_constraints != null)
			{
				for(ActorConstraint constraint in _constraints)
				{
					if(constraint.isEnabled)
					{
						constraint.constrain(this);
					}
				}
			}
		}
	}

	void resolveComponentIndices(List<ActorComponent> components)
	{
		super.resolveComponentIndices(components);

		if(_clips == null)
		{
			return;
		}

		for(ActorClip clip in _clips)
		{
			clip.node = components[clip.clipIdx];
		}
	}

	void completeResolve()
	{
		// Nothing to complete for actornode.
	}

	bool eachChildRecursive(NodeWalkCallback cb)
	{
		if(_children != null)
		{
			for(ActorNode child in _children)
			{
				if(cb(child) == false)
				{
					return false;
				}

				if(child.eachChildRecursive(cb) == false)
				{
					return false;
				}
			}
		}
		return true;
	}

	bool all(NodeWalkCallback cb)
	{
		if(cb(this) == false)
		{
			return false;
		}

		for(ActorNode child in _children)
		{
			if(cb(child) == false)
			{
				return false;
			}

			child.eachChildRecursive(cb);
		}

		return true;
	}
	
	void invalidateShape() {}
}