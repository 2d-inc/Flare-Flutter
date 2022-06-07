import 'dart:typed_data';

import 'package:flare_flutter/base/block_reader.dart';
import 'package:flare_flutter/base/json_block_reader.dart';

abstract class StreamReader {
  int blockType = 0;

  // Instantiate the right type of Reader based on the input values
  factory StreamReader(dynamic data) {
    if (data is ByteData) {
      // Move the readIndex forward for the binary reader.
      return BlockReader(data)
        ..readUint8('F')
        ..readUint8('L')
        ..readUint8('A')
        ..readUint8('R')
        ..readUint8('E');
    } else if (data is Map) {
      return JSONBlockReader(data);
    } else {
      throw ArgumentError('Unexpected type for data');
    }
  }

  String get containerType;

  void closeArray();
  void closeObject();
  bool isEOF();

  void openArray(String label);
  void openObject(String label);
  Uint8List readAsset();
  bool readBool(String label);
  double readFloat32(String label);
  Float32List readFloat32Array(int length, String label);
  double readFloat64(String label);
  int readId(String label);
  int readInt16(String label);
  int readInt32(String label);
  int readInt8(String label);
  StreamReader? readNextBlock(Map<String, int> types);

  String readString(String label);

  int readUint16(String label);

  Uint16List readUint16Array(int length, String label);

  int readUint16Length();

  int readUint32(String label);
  int readUint32Length();
  int readUint8(String label);
  Uint8List readUint8Array(int length, String label);

  int readUint8Length();

  int readVersion();
}
