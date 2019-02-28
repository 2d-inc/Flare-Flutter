class PropertyTypes {
  static const int Unknown = 0;
  static const int PosX = 1;
  static const int PosY = 2;
  static const int ScaleX = 3;
  static const int ScaleY = 4;
  static const int Rotation = 5;
  static const int Opacity = 6;
  static const int DrawOrder = 7;
  static const int Length = 8;
  static const int ImageVertices = 9;
  static const int ConstraintStrength = 10;
  static const int Trigger = 11;
  static const int IntProperty = 12;
  static const int FloatProperty = 13;
  static const int StringProperty = 14;
  static const int BooleanProperty = 15;
  static const int CollisionEnabled = 16;
  static const int Sequence = 17;
  static const int ActiveChildIndex = 18;
  static const int PathVertices = 19;
  static const int FillColor = 20;
  static const int FillGradient = 21;
  static const int FillRadial = 22;
  static const int StrokeColor = 23;
  static const int StrokeGradient = 24;
  static const int StrokeRadial = 25;
  static const int StrokeWidth = 26;
  static const int StrokeOpacity = 27;
  static const int FillOpacity = 28;
  static const int ShapeWidth = 29;
  static const int ShapeHeight = 30;
  static const int CornerRadius = 31;
  static const int InnerRadius = 32;
  static const int StrokeStart = 33;
  static const int StrokeEnd = 34;
  static const int StrokeOffset = 35;
}

const Map<String, int> PropertyTypesMap = {
  "unknown": PropertyTypes.Unknown,
  "posX": PropertyTypes.PosX,
  "posY": PropertyTypes.PosY,
  "scaleX": PropertyTypes.ScaleX,
  "scaleY": PropertyTypes.ScaleY,
  "rotation": PropertyTypes.Rotation,
  "opacity": PropertyTypes.Opacity,
  "drawOrder": PropertyTypes.DrawOrder,
  "length": PropertyTypes.Length,
  "vertices": PropertyTypes.ImageVertices,
  "strength": PropertyTypes.ConstraintStrength,
  "trigger": PropertyTypes.Trigger,
  "intValue": PropertyTypes.IntProperty,
  "floatValue": PropertyTypes.FloatProperty,
  "stringValue": PropertyTypes.StringProperty,
  "boolValue": PropertyTypes.BooleanProperty,
  "isCollisionEnabled": PropertyTypes.CollisionEnabled,
  "sequence": PropertyTypes.Sequence,
  "activeChild": PropertyTypes.ActiveChildIndex,
  "pathVertices": PropertyTypes.PathVertices,
  "fillColor": PropertyTypes.FillColor,
  "fillGradient": PropertyTypes.FillGradient,
  "fillRadial": PropertyTypes.FillRadial,
  "strokeColor": PropertyTypes.StrokeColor,
  "strokeGradient": PropertyTypes.StrokeGradient,
  "strokeRadial": PropertyTypes.StrokeRadial,
  "strokeWidth": PropertyTypes.StrokeWidth,
  "strokeOpacity": PropertyTypes.StrokeOpacity,
  "fillOpacity": PropertyTypes.FillOpacity,
  "width": PropertyTypes.ShapeWidth,
  "height": PropertyTypes.ShapeHeight,
  "cornerRadius": PropertyTypes.CornerRadius,
  "innerRadius": PropertyTypes.InnerRadius,
  "strokeStart": PropertyTypes.StrokeStart,
  "strokeEnd": PropertyTypes.StrokeEnd,
  "strokeOffset": PropertyTypes.StrokeOffset,
};
