import 'dart:typed_data';

import 'package:flare_flutter/base/stream_reader.dart';

/// Implementation of StreamReader that reads binary data.
abstract class BinaryReader implements StreamReader {
  final ByteData _raw;
  int _readIndex = 0;

  ByteData get raw => _raw;
  int get readIndex => _readIndex;

  BinaryReader(ByteData data) : _raw = data;

  ByteData readBytes(int length) {
    int offset = _readIndex + raw.offsetInBytes;
    _readIndex += length;
    return raw.buffer.asByteData(offset, length);
  }

  @override
  double readFloat32([String? label]) {
    double value = _raw.getFloat32(_readIndex, Endian.little);
    _readIndex += 4;

    return value;
  }

  @override
  double readFloat64([String? label]) {
    double value = _raw.getFloat64(_readIndex, Endian.little);
    _readIndex += 8;

    return value;
  }

  @override
  int readUint8([String? label]) {
    return _raw.getUint8(_readIndex++);
  }

  @override
  bool isEOF() {
    return _readIndex >= _raw.lengthInBytes;
  }

  @override
  int readInt8([String? label]) {
    return _raw.getInt8(_readIndex++);
  }

  @override
  int readUint16([String? label]) {
    int value = _raw.getUint16(_readIndex, Endian.little);
    _readIndex += 2;

    return value;
  }

  @override
  Uint16List readUint16Array(int length, [String? label]) {
    Uint16List list = Uint16List(length);
    for (int i = 0; i < length; i++) {
      list[i] = _raw.getUint16(_readIndex, Endian.little);
      _readIndex += 2;
    }
    return list;
  }

  @override
  int readInt16([String? label]) {
    int value = _raw.getInt16(_readIndex, Endian.little);
    _readIndex += 2;

    return value;
  }

  @override
  int readUint32([String? label]) {
    int value = _raw.getUint32(_readIndex, Endian.little);
    _readIndex += 4;

    return value;
  }

  @override
  int readInt32([String? label]) {
    int value = _raw.getInt32(_readIndex, Endian.little);
    _readIndex += 4;

    return value;
  }

  @override
  String readString([String? label]) {
    int length = readUint32();
    int end = _readIndex + length;
    StringBuffer stringBuffer = StringBuffer();

    while (_readIndex < end) {
      int c1 = readUint8();
      if (c1 < 128) {
        stringBuffer.writeCharCode(c1);
      } else if (c1 > 191 && c1 < 224) {
        int c2 = readUint8();
        stringBuffer.writeCharCode((c1 & 31) << 6 | c2 & 63);
      } else if (c1 > 239 && c1 < 365) {
        int c2 = readUint8();
        int c3 = readUint8();
        int c4 = readUint8();
        int u = ((c1 & 7) << 18 | (c2 & 63) << 12 | (c3 & 63) << 6 | c4 & 63) -
            0x10000;
        stringBuffer.writeCharCode(0xD800 + (u >> 10));
        stringBuffer.writeCharCode(0xDC00 + (u & 1023));
      } else {
        int c2 = readUint8();
        int c3 = readUint8();
        stringBuffer.writeCharCode((c1 & 15) << 12 | (c2 & 63) << 6 | c3 & 63);
      }
    }
    return stringBuffer.toString();
  }

  @override
  Uint8List readUint8Array(int length, [String? label]) {
    int offset = _readIndex + _raw.offsetInBytes;
    _readIndex += length;
    return _raw.buffer.asUint8List(offset, length);
  }

  @override
  int readVersion() {
    return readUint32();
  }

  @override
  int readUint8Length() {
    return readUint8();
  }

  @override
  int readUint32Length() {
    return readUint32();
  }

  @override
  int readUint16Length() {
    return readUint16();
  }

  @override
  int readId(String label) {
    return readUint16(label);
  }

  @override
  Float32List readFloat32Array(int length, String label) {
    Float32List list = Float32List(length);
    for (int i = 0; i < length; i++) {
      list[i] = _raw.getFloat32(_readIndex, Endian.little);
      _readIndex += 4;
    }
    return list;
    //int offset = _readIndex;
    //return _raw.buffer.asFloat32List(offset+_raw.offsetInBytes, length);
  }

  @override
  bool readBool(String label) {
    return readUint8(label) == 1;
  }

  @override
  Uint8List readAsset() {
    int length = readUint32();
    return readUint8Array(length);
  }

  @override
  void openArray(String label) {
    /* NOP */
  }

  @override
  void closeArray() {
    /* NOP */
  }

  @override
  void openObject(String label) {
    /* NOP */
  }

  @override
  void closeObject() {
    /* NOP */
  }

  @override
  String get containerType => 'bin';
}
