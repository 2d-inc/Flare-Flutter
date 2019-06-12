import 'dart:typed_data';

import "block_reader.dart";
import "json_block_reader.dart";

abstract class StreamReader {
  int blockType = 0;

  // Instantiate the right type of Reader based on the input values
  factory StreamReader(data) {
    StreamReader reader;
    if (data is ByteData) {
      reader = BlockReader(data);
      // Move the readIndex forward for the binary reader.
      reader.readUint8("F");
      reader.readUint8("L");
      reader.readUint8("A");
      reader.readUint8("R");
      reader.readUint8("E");
    } else if (data is Map) {
      reader = JSONBlockReader(data);
    }
    return reader;
  }

  bool isEOF();

  int readUint8Length();
  int readUint16Length();
  int readUint32Length();

  int readUint8(String label);
  Uint8List readUint8Array(int length, String label);
  int readInt8(String label);
  int readUint16(String label);
  Uint16List readUint16Array(int length, String label);
  int readInt16(String label);
  int readInt32(String label);
  int readUint32(String label);
  int readVersion();
  double readFloat32(String label);
  Float32List readFloat32Array(int length, String label);
  double readFloat64(String label);

  String readString(String label);

  bool readBool(String label);

  int readId(String label);

  StreamReader readNextBlock(Map<String, int> types);

  void openArray(String label);
  void closeArray();
  void openObject(String label);
  void closeObject();

  String get containerType;

  Uint8List readAsset();
}
