class ActorFlags {
  static const int IsDrawOrderDirty = 1 << 0;
  static const int IsDirty = 1 << 1;
}

class DirtyFlags {
  static const int TransformDirty = 1 << 0;
  static const int WorldTransformDirty = 1 << 1;
  static const int PaintDirty = 1 << 2;
}