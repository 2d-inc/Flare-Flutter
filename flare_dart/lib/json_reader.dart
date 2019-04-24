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
    _context = ListQueue();
    _context.addFirst(_readObject);
  }

  dynamic readProp(String label) {
    var head = _context.first;
    if (head is Map) {
      var prop = head[label];
      head.remove(label);
      return prop;
    } else if (head is List) {
      return head.removeAt(0);
    }
    return null;
  }

  @override
  readFloat32(label) {
    num f = this.readProp(label);
    return f.toDouble();
  }

  // Reads the array into ar
  @override
  Float32List readFloat32Array(int length, String label) {
    var ar = Float32List(length);
    this._readArray(ar, label);
	return ar;
  }

  void _readArray(List ar, String label) {
    List array = this.readProp(label);
    for (int i = 0; i < ar.length; i++) {
      num val = array[i];
      ar[i] = ar.first is double ? val.toDouble() : val.toInt();
    }
  }

  @override
  double readFloat64(label) {
    num f = this.readProp(label);
    return f.toDouble();
  }

  @override
  int readUint8(label) {
    return this.readProp(label);
  }

  @override
  int readUint8Length() {
    return this._readLength();
  }

  @override
  bool isEOF() {
    return _context.length <= 1 && _readObject.length == 0;
  }

  @override
  int readInt8(label) {
    return this.readProp(label);
  }

  @override
  int readUint16(label) {
    return this.readProp(label);
  }

  @override
  Uint8List readUint8Array(int length, String label) {
	  var ar = Uint8List(length);
	  this._readArray(ar, label);
    return ar;
  }

  @override
  Uint16List readUint16Array(int length, String label) {
	  var ar = Uint16List(length);
    this._readArray(ar, label);
	return ar;
  }

  @override
  int readInt16(label) {
    return this.readProp(label);
  }

  @override
  int readUint16Length() {
    return this._readLength();
  }

  @override
  int readUint32Length() {
    return this._readLength();
  }

  @override
  int readUint32(label) {
    return this.readProp(label);
  }

  @override
  int readInt32(label) {
    return this.readProp(label);
  }

  @override
  int readVersion() {
    return this.readProp("version");
  }

  @override
  readString(label) {
    return this.readProp(label);
  }

  @override
  readBool(String label) {
    return this.readProp(label);
  }

  // @hasOffset flag is needed for older (up until version 14) files.
  // Since the JSON Reader has been added in version 15, the field here is optional.
  @override
  readId(String label) {
    var val = this.readProp(label);
    return val is num ? val + 1 : 0;
  }

  @override
  openArray(label) {
    var array = this.readProp(label);
    _context.addFirst(array);
  }

  @override
  closeArray() {
    _context.removeFirst();
  }

  @override
  openObject(label) {
    var o = this.readProp(label);
    _context.addFirst(o);
  }

  @override
  closeObject() {
    this._context.removeFirst();
  }

  int _readLength() =>
      _context.first.length; // Maps and Lists both have a `length` property.

  Uint8List readAsset() {
    String encodedAsset =
        readString("data"); // are we sure we need a label here?
    return Base64Decoder().convert(encodedAsset, 22);
  }

  @override
  String get containerType => "json";
  ListQueue get context => _context;
}
