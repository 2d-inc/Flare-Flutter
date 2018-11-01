import "dart:typed_data";
import "dart:convert";

import "actor_component.dart";
import "actor_event.dart";
import "actor_node.dart";
import "actor_node_solo.dart";
import "actor_bone.dart";
import "actor_root_bone.dart";
import "actor_jelly_bone.dart";
import "jelly_component.dart";
import "actor_ik_constraint.dart";
import "actor_rotation_constraint.dart";
import "dependency_sorter.dart";
import "actor_image.dart";
import "actor_shape.dart";
import "actor_ellipse.dart";
import "actor_polygon.dart";
import "actor_rectangle.dart";
import "actor_star.dart";
import "actor_triangle.dart";
import "actor_path.dart";
import "actor_color.dart";
import "actor_drawable.dart";
import "animation/actor_animation.dart";
import "stream_reader.dart";
import "dart:math";

import "math/aabb.dart";

const Map<String, int> BlockTypesMap =
{
	"Unknown": BlockTypes.Unknown,
	"Nodes": BlockTypes.Components,
	"ActorNode": BlockTypes.ActorNode,
	"ActorBone": BlockTypes.ActorBone,
	"ActorRootBone": BlockTypes.ActorRootBone,
	"ActorImage": BlockTypes.ActorImage,
	"View": BlockTypes.View,
	"Animation": BlockTypes.Animation,
	"Animations": BlockTypes.Animations,
	"Atlases": BlockTypes.Atlases,
	"Atlas": BlockTypes.Atlas,
	"ActorIKTarget": BlockTypes.ActorIKTarget,
	"ActorEvent": BlockTypes.ActorEvent,
	"CustomIntProperty": BlockTypes.CustomIntProperty,
	"CustomFloatProperty": BlockTypes.CustomFloatProperty,
	"CustomStringProperty": BlockTypes.CustomStringProperty,
	"CustomBooleanProperty": BlockTypes.CustomBooleanProperty,
	"ActorColliderRectangle": BlockTypes.ActorColliderRectangle,
	"ActorColliderTriangle": BlockTypes.ActorColliderTriangle,
	"ActorColliderCircle": BlockTypes.ActorColliderCircle,
	"ActorColliderPolygon": BlockTypes.ActorColliderPolygon,
	"ActorColliderLine": BlockTypes.ActorColliderLine,
	"ActorImageSequence": BlockTypes.ActorImageSequence,
	"ActorNodeSolo": BlockTypes.ActorNodeSolo,
	"JellyComponent": BlockTypes.JellyComponent,
	"ActorJellyBone": BlockTypes.ActorJellyBone,
	"ActorIKConstraint": BlockTypes.ActorIKConstraint,
	"ActorDistanceConstraint": BlockTypes.ActorDistanceConstraint,
	"ActorTranslationConstraint": BlockTypes.ActorTranslationConstraint,
	"ActorRotationConstraint": BlockTypes.ActorRotationConstraint,
	"ActorScaleConstraint": BlockTypes.ActorScaleConstraint,
	"ActorTransformConstraint": BlockTypes.ActorTransformConstraint,
	"ActorShape": BlockTypes.ActorShape,
	"ActorPath": BlockTypes.ActorPath,
	"ColorFill": BlockTypes.ColorFill,
	"ColorStroke": BlockTypes.ColorStroke,
	"GradientFill": BlockTypes.GradientFill,
	"GradientStroke": BlockTypes.GradientStroke,
	"RadialGradientFill": BlockTypes.RadialGradientFill,
	"RadialGradientStroke": BlockTypes.RadialGradientStroke,
    "ActorEllipse": BlockTypes.ActorEllipse,
    "ActorRectangle": BlockTypes.ActorRectangle,
    "ActorTriangle": BlockTypes.ActorTriangle,
    "ActorStar": BlockTypes.ActorStar,
    "ActorPolygon": BlockTypes.ActorPolygon
};

class BlockTypes
{
	static const int Unknown = 0;
	static const int Components = 1;
	static const int ActorNode = 2;
	static const int ActorBone = 3;
	static const int ActorRootBone = 4;
	static const int ActorImage = 5;
	static const int View = 6;
	static const int Animation = 7;
	static const int Animations = 8;
	static const int Atlases = 9;
	static const int Atlas = 10;
	static const int ActorIKTarget = 11;
	static const int ActorEvent = 12;
	static const int CustomIntProperty = 13;
	static const int CustomFloatProperty = 14;
	static const int CustomStringProperty = 15;
	static const int CustomBooleanProperty = 16;
	static const int ActorColliderRectangle = 17;
	static const int ActorColliderTriangle = 18;
	static const int ActorColliderCircle = 19;
	static const int ActorColliderPolygon = 20;
	static const int ActorColliderLine = 21;
	static const int ActorImageSequence = 22;
	static const int ActorNodeSolo = 23;
	static const int JellyComponent = 28;
	static const int ActorJellyBone = 29;
	static const int ActorIKConstraint = 30;
	static const int ActorDistanceConstraint = 31;
	static const int ActorTranslationConstraint = 32;
	static const int ActorRotationConstraint = 33;
	static const int ActorScaleConstraint = 34;
	static const int ActorTransformConstraint = 35;
	static const int ActorShape = 100;
	static const int ActorPath = 101;
	static const int ColorFill = 102;
	static const int ColorStroke = 103;
	static const int GradientFill = 104;
	static const int GradientStroke = 105;
	static const int RadialGradientFill = 106;
	static const int RadialGradientStroke = 107;
    static const int ActorEllipse = 108;
    static const int ActorRectangle = 109;
    static const int ActorTriangle = 110;
    static const int ActorStar = 111;
    static const int ActorPolygon = 112;
}

class ActorFlags
{
	static const int IsDrawOrderDirty = 1<<0;
	static const int IsVertexDeformDirty = 1<<1;
	static const int IsDirty = 1<<2;
}

class Actor
{
	int _flags = ActorFlags.IsDrawOrderDirty | ActorFlags.IsVertexDeformDirty;
	int _maxTextureIndex = 0;
	int _drawableNodeCount = 0;
	int _nodeCount = 0;
	int _version = 0;
	int _dirtDepth = 0;
	ActorNode _root;
	List<ActorComponent> _components;
	List<ActorNode> _nodes;
	List<ActorDrawable> _drawableNodes;
	List<ActorAnimation> _animations;
	List<ActorComponent> _dependencyOrder;

	Actor();

	bool addDependency(ActorComponent a, ActorComponent b)
	{
		List<ActorComponent> dependents = b.dependents;
		if(dependents == null)
		{
			b.dependents = dependents = new List<ActorComponent>();
		}
		if(dependents.contains(a))
		{
			return false;
		}
		dependents.add(a);
		return true;
	}

	void sortDependencies()
	{
		DependencySorter sorter = new DependencySorter();
		_dependencyOrder = sorter.sort(_root);
		int graphOrder = 0;
		for(ActorComponent component in _dependencyOrder)
		{
			component.graphOrder = graphOrder++;
			component.dirtMask = 255;
		}
		_flags |= ActorFlags.IsDirty;
	}

	bool addDirt(ActorComponent component, int value, bool recurse)
	{
		if((component.dirtMask & value) == value)
		{
			// Already marked.
			return false;
		}

		// Make sure dirt is set before calling anything that can set more dirt.
		int dirt = component.dirtMask | value;
		component.dirtMask = dirt;

		_flags |= ActorFlags.IsDirty;

		component.onDirty(dirt);

		// If the order of this component is less than the current dirt depth, update the dirt depth
		// so that the update loop can break out early and re-run (something up the tree is dirty).
		if(component.graphOrder < _dirtDepth)
		{
			_dirtDepth = component.graphOrder;	
		}
		if(!recurse)
		{
			return true;
		}
		List<ActorComponent> dependents = component.dependents;
		if(dependents != null)
		{
			for(ActorComponent d in dependents)
			{
				addDirt(d, value, recurse);
			}
		}

		return true;
	}

	int get version
	{
		return _version;
	}
	
	List<ActorComponent> get components
	{
		return _components;
	}

	List<ActorNode> get nodes
	{
		return _nodes;
	}

	List<ActorAnimation> get animations
	{
		return _animations;
	}

	List<ActorDrawable> get drawableNodes
	{
		return _drawableNodes;
	}

	ActorComponent operator[](int index)
	{
		return _components[index];
	}

	int get componentCount
	{
		return _components.length;
	}

	int get nodeCount
	{
		return _nodeCount;
	}

	int get imageNodeCount
	{
		return _drawableNodeCount;
	}

	int get texturesUsed
	{
		return _maxTextureIndex + 1;
	}

	ActorNode get root
	{
		return _root;
	}

	ActorAnimation getAnimation(String name)
	{
		for(ActorAnimation a in _animations)
		{
			if(a.name == name)
			{
				return a;
			}
		}
		return null;
	}

	// ActorAnimationInstance getAnimationInstance(String name)
	// {
	// 	ActorAnimation animation = getAnimation(name);
	// 	if(animation == null)
	// 	{
	// 		return null;
	// 	}
	// 	return new ActorAnimationInstance(this, animation);
	// }

	ActorNode getNode(String name)
	{
		for(ActorNode node in _nodes)
		{
			if(node.name == name)
			{
				return node;
			}
		}
		return null;
	}

	void markImageDrawOrderDirty()
	{
		_flags |= ActorFlags.IsDrawOrderDirty;
	}

	bool get isVertexDeformDirty
	{
		return (_flags & ActorFlags.IsVertexDeformDirty) != 0x00;
	}

	void copyActor(Actor actor)
	{
		print("COPYING ACTOR");
		_animations = actor._animations;
		//_flags = actor._flags;
		_maxTextureIndex = actor._maxTextureIndex;
		_drawableNodeCount = actor._drawableNodeCount;
		_nodeCount = actor._nodeCount;

		if(actor.componentCount != 0)
		{
			_components = new List<ActorComponent>(actor.componentCount);
		}
		if(_nodeCount != 0) // This will always be at least 1.
		{
			_nodes = new List<ActorNode>(_nodeCount);
		}
		if(_drawableNodeCount != 0)
		{
			_drawableNodes = new List<ActorDrawable>(_drawableNodeCount);
		}

		if(actor.componentCount != 0)
		{
			int idx = 0;
			int drwIdx = 0;
			int ndIdx = 0;

			for(ActorComponent component in actor.components)
			{
				if(component == null)
				{
					_components[idx++] = null;
					continue;
				}
				ActorComponent instanceComponent = component.makeInstance(this);
				_components[idx++] = instanceComponent;
				if(instanceComponent is ActorNode)
				{
					_nodes[ndIdx++] = instanceComponent;
				}

				if(instanceComponent is ActorDrawable)
				{
					_drawableNodes[drwIdx++] = instanceComponent;
				}
			}
		}

		_root = _components[0] as ActorNode;

		for(ActorComponent component in _components)
		{
			if(_root == component || component == null)
			{
				continue;
			}
			component.resolveComponentIndices(_components);
		}

		for(ActorComponent component in _components)
		{
			if(_root == component || component == null)
			{
				continue;
			}
			print("COMPLETE RESOLVE IN INSTANCE");
			component.completeResolve();
		}

		sortDependencies();

		if (_drawableNodes != null)
		{
			_drawableNodes.sort((a,b) => a.drawOrder.compareTo(b.drawOrder));
			for(int i = 0; i < _drawableNodes.length; i++)
			{
				_drawableNodes[i].drawIndex = i;
			}
		}
	}

	void updateVertexDeform(ActorImage image) {}
	ActorImage makeImageNode()
	{
		return new ActorImage();
	}
	ActorPath makePathNode()
	{
		return new ActorPath();
	}
	ActorShape makeShapeNode()
	{
		return new ActorShape();
	}
    ActorRectangle makeRectangle()
    {
        return new ActorRectangle();
    }
    ActorTriangle makeTriangle()
    {
        return new ActorTriangle();
    }
    ActorStar makeStar()
    {
        return new ActorStar();
    }
    ActorPolygon makePolygon()
    {
        return new ActorPolygon();
    }
    ActorEllipse makeEllipse()
    {
        return new ActorEllipse();
    }
	ColorFill makeColorFill()
	{
		return new ColorFill();
	}
	ColorStroke makeColorStroke()
	{
		return new ColorStroke();
	}
	GradientFill makeGradientFill()
	{
		return new GradientFill();
	}
	GradientStroke makeGradientStroke()
	{
		return new GradientStroke();
	}
	RadialGradientFill makeRadialFill()
	{
		return new RadialGradientFill();
	}
	RadialGradientStroke makeRadialStroke()
	{
		return new RadialGradientStroke();
	}

	void advance(double seconds)
	{
		if((_flags & ActorFlags.IsDirty) != 0)
		{
			const int MaxSteps = 100;
			int step = 0;
			int count = _dependencyOrder.length;
			while((_flags & ActorFlags.IsDirty) != 0 && step < MaxSteps)
			{
				_flags &= ~ActorFlags.IsDirty;
				// Track dirt depth here so that if something else marks dirty, we restart.
				for(int i = 0; i < count; i++)
				{
					ActorComponent component = _dependencyOrder[i];
					_dirtDepth = i;
					int d = component.dirtMask;
					if(d == 0)
					{
						continue;
					}
					component.dirtMask = 0;
					component.update(d);
					if(_dirtDepth < i)
					{
						break;
					}
				}
				step++;
			}
		}

		if((_flags & ActorFlags.IsDrawOrderDirty) != 0)
		{
			_flags &= ~ActorFlags.IsDrawOrderDirty;

			if (_drawableNodes != null)
			{
				_drawableNodes.sort((a,b) => a.drawOrder.compareTo(b.drawOrder));
				for(int i = 0; i < _drawableNodes.length; i++)
				{
					_drawableNodes[i].drawIndex = i;
				}
			}
		}
		if((_flags & ActorFlags.IsVertexDeformDirty) != 0)
		{
			_flags &= ~ActorFlags.IsVertexDeformDirty;
			for(int i = 0; i < _drawableNodeCount; i++)
			{
				ActorDrawable drawable = _drawableNodes[i];
				if(drawable is ActorImage && drawable.isVertexDeformDirty)
				{
					drawable.isVertexDeformDirty = false;
					updateVertexDeform(drawable);
				}
			}
		}
	}

	void load(ByteData data)
	{
		if(data.lengthInBytes < 5)
		{
			throw new UnsupportedError("Not a valid Flare file.");
		}
        int F = data.getUint8(0);
        int L = data.getUint8(1);
        int A = data.getUint8(2);
        int R = data.getUint8(3);
        int E = data.getUint8(4);

		dynamic inputData = data;

		if(F != 70 || L != 76 || A != 65 || R != 82 || E != 69)
		{
            Uint8List charCodes = data.buffer.asUint8List();
            String stringData = String.fromCharCodes(charCodes);
            var jsonActor = jsonDecode(stringData);
            Map jsonObject = new Map();
            jsonObject["container"] = jsonActor;
            inputData = jsonObject;
		}

        StreamReader reader = new StreamReader(inputData);
		_version = reader.readVersion();
	
		_root = new ActorNode.withActor(this);

		StreamReader block;
		while((block=reader.readNextBlock(BlockTypesMap)) != null)
		{
			switch(block.blockType)
			{
				case BlockTypes.Components:
					readComponentsBlock(block);
					break;
				case BlockTypes.Animations:
					readAnimationsBlock(block);
					break;
			}
		}
	}

	void readComponentsBlock(StreamReader block)
	{
		int componentCount = block.readUint16Length();
		_components = new List<ActorComponent>(componentCount+1);
		_components[0] = _root;

		// Guaranteed from the exporter to be in index order.
		StreamReader nodeBlock;

		int componentIndex = 1;
		_nodeCount = 1;
		while((nodeBlock=block.readNextBlock(BlockTypesMap)) != null)
		{
			ActorComponent component;
			switch(nodeBlock.blockType)
			{
				case BlockTypes.ActorNode:
					component = ActorNode.read(this, nodeBlock, null);
					break;

				case BlockTypes.ActorBone:
					component = ActorBone.read(this, nodeBlock, null);
					break;

				case BlockTypes.ActorRootBone:
					component = ActorRootBone.read(this, nodeBlock, null);
					break;

				case BlockTypes.ActorImageSequence:
					component = ActorImage.readSequence(this, nodeBlock, makeImageNode());
					ActorImage ai = component as ActorImage;
					_maxTextureIndex = ai.sequenceFrames.last.atlasIndex; // Last atlasIndex is the biggest
					break;

				case BlockTypes.ActorImage:
					component = ActorImage.read(this, nodeBlock, makeImageNode());
					if((component as ActorImage).textureIndex > _maxTextureIndex)
					{
						_maxTextureIndex = (component as ActorImage).textureIndex;
					}
					break;

				case BlockTypes.ActorIKTarget:
					//component = ActorIKTarget.Read(this, nodeBlock);
					break;

				case BlockTypes.ActorEvent:
					component = ActorEvent.read(this, nodeBlock,  null);
					break;

				case BlockTypes.CustomIntProperty:
					//component = CustomIntProperty.Read(this, nodeBlock);
					break;

				case BlockTypes.CustomFloatProperty:
					//component = CustomFloatProperty.Read(this, nodeBlock);
					break;

				case BlockTypes.CustomStringProperty:
					//component = CustomStringProperty.Read(this, nodeBlock);
					break;

				case BlockTypes.CustomBooleanProperty:
					//component = CustomBooleanProperty.Read(this, nodeBlock);
					break;

				case BlockTypes.ActorColliderRectangle:
					//component = ActorColliderRectangle.Read(this, nodeBlock);
					break;

				case BlockTypes.ActorColliderTriangle:
					//component = ActorColliderTriangle.Read(this, nodeBlock);
					break;

				case BlockTypes.ActorColliderCircle:
					//component = ActorColliderCircle.Read(this, nodeBlock);
					break;

				case BlockTypes.ActorColliderPolygon:
					//component = ActorColliderPolygon.Read(this, nodeBlock);
					break;

				case BlockTypes.ActorColliderLine:
					//component = ActorColliderLine.Read(this, nodeBlock);
					break;

				case BlockTypes.ActorNodeSolo:
					component = ActorNodeSolo.read(this, nodeBlock, null);
					break;

				case BlockTypes.ActorJellyBone:
					component = ActorJellyBone.read(this, nodeBlock, null);
					break;

				case BlockTypes.JellyComponent:
					component = JellyComponent.read(this, nodeBlock, null);
					break;

				case BlockTypes.ActorIKConstraint:
					component = ActorIKConstraint.read(this, nodeBlock, null);
					break;

				case BlockTypes.ActorDistanceConstraint:
					//component = ActorDistanceConstraint.Read(this, nodeBlock);
					break;

				case BlockTypes.ActorTranslationConstraint:
					//component = ActorTranslationConstraint.Read(this, nodeBlock);
					break;

				case BlockTypes.ActorScaleConstraint:
					//component = ActorScaleConstraint.Read(this, nodeBlock);
					break;

				case BlockTypes.ActorRotationConstraint:
					component = ActorRotationConstraint.read(this, nodeBlock, null);
					break;

				case BlockTypes.ActorTransformConstraint:
					//component = ActorTransformConstraint.Read(this, nodeBlock);
					break;

				case BlockTypes.ActorShape:
					component = ActorShape.read(this, nodeBlock, makeShapeNode());
					break;

				case BlockTypes.ActorPath:
					component = ActorPath.read(this, nodeBlock, makePathNode());
					break;

				case BlockTypes.ColorFill:
					component = ColorFill.read(this, nodeBlock, makeColorFill());
					break;
					
				case BlockTypes.ColorStroke:
					component = ColorStroke.read(this, nodeBlock, makeColorStroke());
					break;
					
				case BlockTypes.GradientFill:
					component = GradientFill.read(this, nodeBlock, makeGradientFill());
					break;
					
				case BlockTypes.GradientStroke:
					component = GradientStroke.read(this, nodeBlock, makeGradientStroke());
					break;
					
				case BlockTypes.RadialGradientFill:
					component = RadialGradientFill.read(this, nodeBlock, makeRadialFill());
					break;
					
				case BlockTypes.RadialGradientStroke:
					component = RadialGradientStroke.read(this, nodeBlock, makeRadialStroke());
					break;

                case BlockTypes.ActorEllipse:
                    component = ActorEllipse.read(this, nodeBlock, makeEllipse());
                    break; 

                case BlockTypes.ActorRectangle:
                    component = ActorRectangle.read(this, nodeBlock, makeRectangle());
                    break;
                    
                case BlockTypes.ActorTriangle:
                    component = ActorTriangle.read(this, nodeBlock, makeTriangle());
                    break; 
                    
                case BlockTypes.ActorStar:
                    component = ActorStar.read(this, nodeBlock, makeStar());
                    break; 
                    
                case BlockTypes.ActorPolygon:
                    component = ActorPolygon.read(this, nodeBlock, makePolygon());
                    break;
			}
			if(component is ActorDrawable)
			{
				_drawableNodeCount++;
			}

			if(component is ActorNode)
			{
				_nodeCount++;
			}

			_components[componentIndex] = component;
			if(component != null)
			{
				component.idx = componentIndex;
			}
			componentIndex++;
		}

		_drawableNodes = new List<ActorDrawable>(_drawableNodeCount);
		_nodes = new List<ActorNode>(_nodeCount);
		_nodes[0] = _root;

		// Resolve nodes.
		int drwIdx = 0;
		int anIdx = 0;

		for(int i = 1; i <= componentCount; i++)
		{
			ActorComponent c = _components[i];
			// Nodes can be null if we read from a file version that contained nodes that we don't interpret in this runtime.
			if(c != null)
			{
				c.resolveComponentIndices(_components);
			}

			if(c is ActorDrawable)
			{
				_drawableNodes[drwIdx++] = c;
			}

			if(c is ActorNode)
			{
				ActorNode an = c;
				if(an != null)
				{
					_nodes[anIdx++] = an;
				}
			}
		}

		for(int i = 1; i <= componentCount; i++)
		{
			ActorComponent c = components[i];
			if(c != null)
			{
				c.completeResolve();
			}
		}

		sortDependencies();
	}

	void readAnimationsBlock(StreamReader block)
	{
		// Read animations.
		int animationCount = block.readUint16Length();
		_animations = new List<ActorAnimation>(animationCount);
		StreamReader animationBlock;
		int animationIndex = 0;
		
		while((animationBlock=block.readNextBlock(BlockTypesMap)) != null)
		{
			switch(animationBlock.blockType)
			{
				case BlockTypes.Animation:
					ActorAnimation anim = ActorAnimation.read(animationBlock, _components);
					_animations[animationIndex++] = anim;
					break;
			}
		}
	}

	AABB computeAABB()
	{
		AABB aabb;
		for(ActorDrawable drawable in _drawableNodes)
		{
			// This is the axis aligned bounding box in the space of the parent (this case our shape).
			AABB pathAABB = drawable.computeAABB();

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

		return aabb;
	}
}