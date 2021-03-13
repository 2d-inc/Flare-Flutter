import 'package:flare_flutter/base/json_reader.dart';

class JSONBlockReader extends JSONReader {
  @override
  int blockType;

  JSONBlockReader(Map object)
      : blockType = 0,
        super(object);
  JSONBlockReader.fromObject(this.blockType, Map object) : super(object);

  @override
  JSONBlockReader? readNextBlock(Map<String, int> blockTypes) {
    if (isEOF()) {
      return null;
    }

    var obj = <dynamic, dynamic>{};
    obj['container'] = _peek();
    var type = readBlockType(blockTypes);
    dynamic c = context.first;
    if (c is Map) {
      c.remove(nextKey);
    } else if (c is List) {
      c.removeAt(0);
    }

    return JSONBlockReader.fromObject(type, obj);
  }

  int readBlockType(Map<String, int> blockTypes) {
    dynamic next = _peek();
    if (next is Map) {
      dynamic c = context.first;
      if (c is Map) {
        return blockTypes[nextKey]!;
      } else if (c is List) {
        // Objects are serialized with "type" property.
        return blockTypes[next['type']]!;
      }
    } else if (next is List) {
      // Arrays are serialized as "type": [Array].
      return blockTypes[nextKey]!;
    }
    // Unknown type.
    return 0;
  }

  dynamic _peek() {
    dynamic stream = context.first;
    dynamic next;
    if (stream is Map) {
      next = stream[nextKey];
    } else if (stream is List) {
      next = stream[0];
    }
    return next;
  }

  dynamic get nextKey => context.first.keys.first;
}
