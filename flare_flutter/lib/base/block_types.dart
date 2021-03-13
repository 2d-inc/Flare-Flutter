const Map<String, int> blockTypesMap = {
  'unknown': BlockTypes.unknown,
  'nodes': BlockTypes.components,
  'node': BlockTypes.actorNode,
  'bone': BlockTypes.actorBone,
  'rootBone': BlockTypes.actorRootBone,
  'image': BlockTypes.actorImage,
  'view': BlockTypes.view,
  'animation': BlockTypes.animation,
  'animations': BlockTypes.animations,
  'atlases': BlockTypes.atlases,
  'atlas': BlockTypes.atlas,
  'event': BlockTypes.actorEvent,
  'customInt': BlockTypes.customIntProperty,
  'customFloat': BlockTypes.customFloatProperty,
  'customString': BlockTypes.customStringProperty,
  'customBoolean': BlockTypes.customBooleanProperty,
  'rectangleCollider': BlockTypes.actorColliderRectangle,
  'triangleCollider': BlockTypes.actorColliderTriangle,
  'circleCollider': BlockTypes.actorColliderCircle,
  'polygonCollider': BlockTypes.actorColliderPolygon,
  'lineCollider': BlockTypes.actorColliderLine,
  'imageSequence': BlockTypes.actorImageSequence,
  'solo': BlockTypes.actorNodeSolo,
  'jelly': BlockTypes.jellyComponent,
  'jellyBone': BlockTypes.actorJellyBone,
  'ikConstraint': BlockTypes.actorIKConstraint,
  'distanceConstraint': BlockTypes.actorDistanceConstraint,
  'translationConstraint': BlockTypes.actorTranslationConstraint,
  'rotationConstraint': BlockTypes.actorRotationConstraint,
  'scaleConstraint': BlockTypes.actorScaleConstraint,
  'transformConstraint': BlockTypes.actorTransformConstraint,
  'shape': BlockTypes.actorShape,
  'path': BlockTypes.actorPath,
  'colorFill': BlockTypes.colorFill,
  'colorStroke': BlockTypes.colorStroke,
  'gradientFill': BlockTypes.gradientFill,
  'gradientStroke': BlockTypes.gradientStroke,
  'radialGradientFill': BlockTypes.radialGradientFill,
  'radialGradientStroke': BlockTypes.radialGradientStroke,
  'ellipse': BlockTypes.actorEllipse,
  'rectangle': BlockTypes.actorRectangle,
  'triangle': BlockTypes.actorTriangle,
  'star': BlockTypes.actorStar,
  'polygon': BlockTypes.actorPolygon,
  'artboards': BlockTypes.artboards,
  'artboard': BlockTypes.actorArtboard,
  'effectRenderer': BlockTypes.actorLayerEffectRenderer,
  'mask': BlockTypes.actorMask,
  'blur': BlockTypes.actorBlur,
  'dropShadow': BlockTypes.actorDropShadow,
  'innerShadow': BlockTypes.actorInnerShadow
};

class BlockTypes {
  static const int unknown = 0;
  static const int components = 1;
  static const int actorNode = 2;
  static const int actorBone = 3;
  static const int actorRootBone = 4;
  static const int actorImage = 5;
  static const int view = 6;
  static const int animation = 7;
  static const int animations = 8;
  static const int atlases = 9;
  static const int atlas = 10;
  static const int actorIKTarget = 11;
  static const int actorEvent = 12;
  static const int customIntProperty = 13;
  static const int customFloatProperty = 14;
  static const int customStringProperty = 15;
  static const int customBooleanProperty = 16;
  static const int actorColliderRectangle = 17;
  static const int actorColliderTriangle = 18;
  static const int actorColliderCircle = 19;
  static const int actorColliderPolygon = 20;
  static const int actorColliderLine = 21;
  static const int actorImageSequence = 22;
  static const int actorNodeSolo = 23;
  static const int jellyComponent = 28;
  static const int actorJellyBone = 29;
  static const int actorIKConstraint = 30;
  static const int actorDistanceConstraint = 31;
  static const int actorTranslationConstraint = 32;
  static const int actorRotationConstraint = 33;
  static const int actorScaleConstraint = 34;
  static const int actorTransformConstraint = 35;
  static const int actorShape = 100;
  static const int actorPath = 101;
  static const int colorFill = 102;
  static const int colorStroke = 103;
  static const int gradientFill = 104;
  static const int gradientStroke = 105;
  static const int radialGradientFill = 106;
  static const int radialGradientStroke = 107;
  static const int actorEllipse = 108;
  static const int actorRectangle = 109;
  static const int actorTriangle = 110;
  static const int actorStar = 111;
  static const int actorPolygon = 112;
  static const int actorSkin = 113;
  static const int actorArtboard = 114;
  static const int artboards = 115;
  static const int actorLayerEffectRenderer = 116;
  static const int actorMask = 117;
  static const int actorBlur = 118;
  static const int actorDropShadow = 119;
  static const int actorInnerShadow = 120;
}
