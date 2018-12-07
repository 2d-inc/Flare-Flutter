const Map<String, int> BlockTypesMap = {
  "unknown": BlockTypes.Unknown,
  "nodes": BlockTypes.Components,
  "node": BlockTypes.ActorNode,
  "bone": BlockTypes.ActorBone,
  "rootBone": BlockTypes.ActorRootBone,
  "image": BlockTypes.ActorImage,
  "view": BlockTypes.View,
  "animation": BlockTypes.Animation,
  "animations": BlockTypes.Animations,
  "atlases": BlockTypes.Atlases,
  "atlas": BlockTypes.Atlas,
  "event": BlockTypes.ActorEvent,
  "customInt": BlockTypes.CustomIntProperty,
  "customFloat": BlockTypes.CustomFloatProperty,
  "customString": BlockTypes.CustomStringProperty,
  "customBoolean": BlockTypes.CustomBooleanProperty,
  "rectangleCollider": BlockTypes.ActorColliderRectangle,
  "triangleCollider": BlockTypes.ActorColliderTriangle,
  "circleCollider": BlockTypes.ActorColliderCircle,
  "polygonCollider": BlockTypes.ActorColliderPolygon,
  "lineCollider": BlockTypes.ActorColliderLine,
  "imageSequence": BlockTypes.ActorImageSequence,
  "solo": BlockTypes.ActorNodeSolo,
  "jelly": BlockTypes.JellyComponent,
  "jellyBone": BlockTypes.ActorJellyBone,
  "ikConstraint": BlockTypes.ActorIKConstraint,
  "distanceConstraint": BlockTypes.ActorDistanceConstraint,
  "translationConstraint": BlockTypes.ActorTranslationConstraint,
  "rotationConstraint": BlockTypes.ActorRotationConstraint,
  "scaleConstraint": BlockTypes.ActorScaleConstraint,
  "transformConstraint": BlockTypes.ActorTransformConstraint,
  "shape": BlockTypes.ActorShape,
  "path": BlockTypes.ActorPath,
  "colorFill": BlockTypes.ColorFill,
  "colorStroke": BlockTypes.ColorStroke,
  "gradientFill": BlockTypes.GradientFill,
  "gradientStroke": BlockTypes.GradientStroke,
  "radialGradientFill": BlockTypes.RadialGradientFill,
  "radialGradientStroke": BlockTypes.RadialGradientStroke,
  "ellipse": BlockTypes.ActorEllipse,
  "rectangle": BlockTypes.ActorRectangle,
  "triangle": BlockTypes.ActorTriangle,
  "star": BlockTypes.ActorStar,
  "polygon": BlockTypes.ActorPolygon,
  "artboards": BlockTypes.Artboards,
  "artboard": BlockTypes.ActorArtboard
};

class BlockTypes {
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
  static const int ActorSkin = 113;
  static const int ActorArtboard = 114;
  static const int Artboards = 115;
}
