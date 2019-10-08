import "json_reader.dart";

class JSONBlockReader extends JSONReader {
  JSONBlockReader(Map object) : super(object);

  JSONBlockReader.fromObject(int type, Map object) : super(object) {
    blockType = type;
  }

  @override
  JSONBlockReader readNextBlock([Map<String, int> blockTypes]) {
    if (isEOF()) {
      return null;
    }

    var obj = <dynamic, dynamic>{};
    obj["container"] = _peek();
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
    int bType;
    if (next is Map) {
      dynamic c = context.first;
      if (c is Map) {
        bType = blockTypes[nextKey];
      } else if (c is List) {
        // Objects are serialized with "type" property.
        dynamic nType = next["type"];
        bType = blockTypes[nType];
      }
    } else if (next is List) {
      // Arrays are serialized as "type": [Array].
      bType = blockTypes[nextKey];
    }
    return bType;
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
