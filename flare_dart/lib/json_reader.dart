import "dart:collection";
import 'dart:convert';
import "dart:typed_data";

import "stream_reader.dart";

abstract class JSONReader implements StreamReader {
  @override
  int blockType;

  dynamic _readObject;
  ListQueue _context;

  JSONReader(Map object) {
    _readObject = object["container"];
    _context = ListQueue<dynamic>();
    _context.addFirst(_readObject);
  }

  dynamic readProp(String label) {
    dynamic head = _context.first;
    if (head is Map) {
      dynamic prop = head[label];
      head.remove(label);
      return prop;
    } else if (head is List) {
      return head.removeAt(0);
    }
    return null;
  }

  @override
  double readFloat32(String label) {
    dynamic f = readProp(label);
    if (f is num) {
      return f.toDouble();
    }
    return 0;
  }

  // Reads the array into ar
  @override
  Float32List readFloat32Array(int length, String label) {
    var ar = Float32List(length);
    _readArray(ar, label);
    return ar;
  }

  void _readArray(List ar, String label) {
    List array = readProp(label) as List;
    for (int i = 0; i < ar.length; i++) {
      num val = array[i] as num;
      ar[i] = ar.first is double ? val.toDouble() : val.toInt();
    }
  }

  @override
  double readFloat64(String label) {
    num f = readProp(label) as num;
    return f.toDouble();
  }

  @override
  int readUint8(String label) {
    return readProp(label) as int;
  }

  @override
  int readUint8Length() {
    return _readLength();
  }

  @override
  bool isEOF() {
    return _context.length <= 1 && _readObject.length == 0;
  }

  @override
  int readInt8(String label) {
    return readProp(label) as int;
  }

  @override
  int readUint16(String label) {
    return readProp(label) as int;
  }

  @override
  Uint8List readUint8Array(int length, String label) {
    var ar = Uint8List(length);
    _readArray(ar, label);
    return ar;
  }

  @override
  Uint16List readUint16Array(int length, String label) {
    var ar = Uint16List(length);
    _readArray(ar, label);
    return ar;
  }

  @override
  int readInt16(String label) {
    return readProp(label) as int;
  }

  @override
  int readUint16Length() {
    return _readLength();
  }

  @override
  int readUint32Length() {
    return _readLength();
  }

  @override
  int readUint32(String label) {
    return readProp(label) as int;
  }

  @override
  int readInt32(String label) {
    return readProp(label) as int;
  }

  @override
  int readVersion() {
    return readProp("version") as int;
  }

  @override
  String readString(String label) {
    return readProp(label) as String;
  }

  @override
  bool readBool(String label) {
    return readProp(label) as bool;
  }

  // @hasOffset flag is needed for older (up until version 14) files.
  // Since the JSON Reader has been added in version 15, the field here is optional.
  @override
  int readId(String label) {
    dynamic val = readProp(label);
    return val is num ? val.toInt() + 1 : 0;
  }

  @override
  void openArray(String label) {
    dynamic array = readProp(label);
    _context.addFirst(array);
  }

  @override
  void closeArray() {
    _context.removeFirst();
  }

  @override
  void openObject(String label) {
    dynamic o = readProp(label);
    _context.addFirst(o);
  }

  @override
  void closeObject() {
    _context.removeFirst();
  }

  int _readLength() {
    dynamic next = _context.first;
    if (next is Map) {
      return next.length;
    } else if (next is List) {
      return next.length;
    }
    return 0;
  }

  @override
  Uint8List readAsset() {
    String encodedAsset =
        readString("data"); // are we sure we need a label here?
    return const Base64Decoder().convert(encodedAsset, 22);
  }

  @override
  String get containerType => "json";
  ListQueue get context => _context;
}
