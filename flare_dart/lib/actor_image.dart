import 'dart:typed_data';
import 'package:flare_dart/actor_skinnable.dart';

import "stream_reader.dart";
import "math/mat2d.dart";
import "actor_artboard.dart";
import "actor_component.dart";
import "actor_drawable.dart";
import "math/aabb.dart";

class SequenceFrame {
  final int _atlasIndex;
  final int _offset;
  SequenceFrame(this._atlasIndex, this._offset);

  @override
  String toString() {
    return "(" + _atlasIndex.toString() + ", " + _offset.toString() + ")";
  }

  int get atlasIndex => _atlasIndex;
  int get offset => _offset;
}

class ActorImage extends ActorDrawable with ActorSkinnable {
  @override
  int drawIndex;

  @override
  int drawOrder;

  int _textureIndex = -1;
  Float32List _vertices;
  Uint16List _triangles;
  int _vertexCount = 0;
  int _triangleCount = 0;
  Float32List _animationDeformedVertices;

  List<SequenceFrame> _sequenceFrames;
  Float32List _sequenceUVs;
  int _sequenceFrame = 0;

  int get sequenceFrame => _sequenceFrame;

  Float32List get sequenceUVs => _sequenceUVs;

  List<SequenceFrame> get sequenceFrames => _sequenceFrames;

  set sequenceFrame(int value) {
    _sequenceFrame = value;
  }

  int get textureIndex {
    return _textureIndex;
  }

  int get vertexCount {
    return _vertexCount;
  }

  int get triangleCount {
    return _triangleCount;
  }

  Uint16List get triangles {
    return _triangles;
  }

  Float32List get vertices {
    return _vertices;
  }

  int get vertexPositionOffset {
    return 0;
  }

  int get vertexUVOffset {
    return 2;
  }

  int get vertexBoneIndexOffset {
    return 4;
  }

  int get vertexBoneWeightOffset {
    return 8;
  }

  int get vertexStride {
    return isConnectedToBones ? 12 : 4;
  }

  bool get doesAnimationVertexDeform {
    return _animationDeformedVertices != null;
  }

  set doesAnimationVertexDeform(bool value) {
    if (value) {
      if (_animationDeformedVertices == null ||
          _animationDeformedVertices.length != _vertexCount * 2) {
        _animationDeformedVertices = Float32List(vertexCount * 2);
        // Copy the deform verts from the rig verts.
        int writeIdx = 0;
        int readIdx = 0;
        int readStride = vertexStride;
        for (int i = 0; i < _vertexCount; i++) {
          _animationDeformedVertices[writeIdx++] = _vertices[readIdx];
          _animationDeformedVertices[writeIdx++] = _vertices[readIdx + 1];
          readIdx += readStride;
        }
      }
    } else {
      _animationDeformedVertices = null;
    }
  }

  Float32List get animationDeformedVertices {
    return _animationDeformedVertices;
  }

  ActorImage();

  void disposeGeometry() {
    // Delete vertices only if we do not vertex deform at runtime.
    if (_animationDeformedVertices == null) {
      _vertices = null;
    }
    _triangles = null;
  }

  static ActorImage read(
      ActorArtboard artboard, StreamReader reader, ActorImage node) {
    if (node == null) {
      node = ActorImage();
    }

    ActorDrawable.read(artboard, reader, node);
    ActorSkinnable.read(artboard, reader, node);

    if (!node.isHidden) {
      node._textureIndex = reader.readUint8("atlas");

      int numVertices = reader.readUint32("numVertices");

      node._vertexCount = numVertices;
      node._vertices =
          reader.readFloat32Array(numVertices * node.vertexStride, "vertices");

      int numTris = reader.readUint32("numTriangles");
      node._triangles = Uint16List(numTris * 3);
      node._triangleCount = numTris;
      node._triangles = reader.readUint16Array(numTris * 3, "triangles");
    }
    return node;
  }

// TODO: fix sequences for flare.
//   static ActorImage readSequence(
//       ActorArtboard artboard, StreamReader reader, ActorImage node) {
//     ActorImage.read(artboard, reader, node);

//     if (node._textureIndex != -1) {
//       reader.openArray("frames");
//       int frameAssetCount = reader.readUint16Length();
//       // node._sequenceFrames = [];
//       Float32List uvs = Float32List(node._vertexCount * 2 * frameAssetCount);
//       int uvStride = node._vertexCount * 2;
//       node._sequenceUVs = uvs;
//       SequenceFrame firstFrame = SequenceFrame(node._textureIndex, 0);
//       node._sequenceFrames = List<SequenceFrame>();
//       node._sequenceFrames.add(firstFrame);
//       int readIdx = 2;
//       int writeIdx = 0;
//       int vertexStride = 4;
//       if (node._boneConnections != null && node._boneConnections.length > 0) {
//         vertexStride = 12;
//       }
//       for (int i = 0; i < node._vertexCount; i++) {
//         uvs[writeIdx++] = node._vertices[readIdx];
//         uvs[writeIdx++] = node._vertices[readIdx + 1];
//         readIdx += vertexStride;
//       }

//       int offset = uvStride;
//       for (int i = 1; i < frameAssetCount; i++) {
//         reader.openObject("frame");

//         SequenceFrame frame =
//             SequenceFrame(reader.readUint8("atlas"), offset * 4);
//         node._sequenceFrames.add(frame);
//         reader.readFloat32ArrayOffset(uvs, uvStride, offset, "uv");
//         offset += uvStride;

//         reader.closeObject();
//       }

//       reader.closeArray();
//     }

//     return node;
//   }

  void resolveComponentIndices(List<ActorComponent> components) {
    super.resolveComponentIndices(components);
    resolveSkinnable(components);
  }

  ActorComponent makeInstance(ActorArtboard resetArtboard) {
    ActorImage instanceNode = resetArtboard.actor.makeImageNode();
    instanceNode.copyImage(this, resetArtboard);
    return instanceNode;
  }

  void copyImage(ActorImage node, ActorArtboard resetArtboard) {
    copyDrawable(node, resetArtboard);
    copySkinnable(node, resetArtboard);

    _textureIndex = node._textureIndex;
    _vertexCount = node._vertexCount;
    _triangleCount = node._triangleCount;
    _vertices = node._vertices;
    _triangles = node._triangles;
    if (node._animationDeformedVertices != null) {
      _animationDeformedVertices =
          Float32List.fromList(node._animationDeformedVertices);
    }
  }

//   void transformBind(Mat2D xform) {
//     if (_boneConnections != null) {
//       for (BoneConnection bc in _boneConnections) {
//         Mat2D.multiply(bc.bind, xform, bc.bind);
//         Mat2D.invert(bc.inverseBind, bc.bind);
//       }
//     }
//   }

  Float32List makeVertexPositionBuffer() {
    return Float32List(_vertexCount * 2);
  }

  Float32List makeVertexUVBuffer() {
    return Float32List(_vertexCount * 2);
  }

  void transformDeformVertices(Mat2D wt) {
    if (_animationDeformedVertices == null) {
      return;
    }

    Float32List fv = _animationDeformedVertices;

    int vidx = 0;
    for (int j = 0; j < _vertexCount; j++) {
      double x = fv[vidx];
      double y = fv[vidx + 1];

      fv[vidx] = wt[0] * x + wt[2] * y + wt[4];
      fv[vidx + 1] = wt[1] * x + wt[3] * y + wt[5];

      vidx += 2;
    }
  }

  void updateVertexUVBuffer(Float32List buffer) {
    int readIdx = vertexUVOffset;
    int writeIdx = 0;
    int stride = vertexStride;

    Float32List v = _vertices;
    for (int i = 0; i < _vertexCount; i++) {
      buffer[writeIdx++] = v[readIdx];
      buffer[writeIdx++] = v[readIdx + 1];
      readIdx += stride;
    }
  }

  void updateVertexPositionBuffer(
      Float32List buffer, bool isSkinnedDeformInWorld) {
    Mat2D worldTransform = this.worldTransform;
    int readIdx = 0;
    int writeIdx = 0;

    Float32List v = _animationDeformedVertices != null
        ? _animationDeformedVertices
        : _vertices;
    int stride = _animationDeformedVertices != null ? 2 : vertexStride;

    if (skin != null) {
      Float32List boneTransforms = skin.boneMatrices;

      //Mat2D inverseWorldTransform = Mat2D.Invert(new Mat2D(), worldTransform);
      Float32List influenceMatrix =
          Float32List.fromList([0.0, 0.0, 0.0, 0.0, 0.0, 0.0]);

      // if(this.name == "evolution_1_0001s_0003_evolution_1_weapo")
      // {
      // //	print("TEST!");
      // 	int boneIndexOffset = vertexBoneIndexOffset;
      // 	int weightOffset = vertexBoneWeightOffset;
      // 	for(int i = 0; i < _vertexCount; i++)
      // 	{
      // 		for(int wi = 0; wi < 4; wi++)
      // 		{
      // 			int boneIndex = _vertices[boneIndexOffset+wi].toInt();
      // 			double weight = _vertices[weightOffset+wi];
      // 			if(boneIndex == 1)
      // 			{
      // 				_vertices[weightOffset+wi] = 1.0;
      // 			}
      // 			else if(boneIndex == 2)
      // 			{
      // 				_vertices[weightOffset+wi] = 0.0;
      // 			}
      // 			//print("BI $boneIndex $weight");
      // 		}
      // 		boneIndexOffset += vertexStride;
      // 		weightOffset += vertexStride;
      // 	}
      // }
      int boneIndexOffset = vertexBoneIndexOffset;
      int weightOffset = vertexBoneWeightOffset;
      for (int i = 0; i < _vertexCount; i++) {
        double x = v[readIdx];
        double y = v[readIdx + 1];

        double px, py;

        if (_animationDeformedVertices != null && isSkinnedDeformInWorld) {
          px = x;
          py = y;
        } else {
          px =
              worldTransform[0] * x + worldTransform[2] * y + worldTransform[4];
          py =
              worldTransform[1] * x + worldTransform[3] * y + worldTransform[5];
        }

        influenceMatrix[0] = influenceMatrix[1] = influenceMatrix[2] =
            influenceMatrix[3] = influenceMatrix[4] = influenceMatrix[5] = 0.0;

        for (int wi = 0; wi < 4; wi++) {
          int boneIndex = _vertices[boneIndexOffset + wi].toInt();
          double weight = _vertices[weightOffset + wi];

          int boneTransformIndex = boneIndex * 6;
          if (boneIndex <= connectedBones.length) {
            for (int j = 0; j < 6; j++) {
              influenceMatrix[j] +=
                  boneTransforms[boneTransformIndex + j] * weight;
            }
          }
        }

        x = influenceMatrix[0] * px +
            influenceMatrix[2] * py +
            influenceMatrix[4];
        y = influenceMatrix[1] * px +
            influenceMatrix[3] * py +
            influenceMatrix[5];

        readIdx += stride;
        boneIndexOffset += vertexStride;
        weightOffset += vertexStride;

        buffer[writeIdx++] = x;
        buffer[writeIdx++] = y;
      }
    } else {
      for (int i = 0; i < _vertexCount; i++) {
        buffer[writeIdx++] = v[readIdx];
        buffer[writeIdx++] = v[readIdx + 1];
        readIdx += stride;
      }
    }
  }

  @override
  AABB computeAABB() {
    // Todo: implement for image.
    Mat2D worldTransform = this.worldTransform;
    return AABB.fromValues(worldTransform[4], worldTransform[5],
        worldTransform[4], worldTransform[5]);
  }

  Mat2D get imageTransform => isConnectedToBones ? null : worldTransform;

  @override
  void initializeGraphics() {}

  @override
  void invalidateDrawable() {}

  @override
  int get blendModeId {
    return 0;
  }

  @override
  set blendModeId(int value) {}
}
