import "json_reader.dart";

class JSONBlockReader extends JSONReader {
  @override
  int blockType;

  JSONBlockReader(Map object)
      : blockType = 0,
        super(object);

  JSONBlockReader.fromObject(int type, Map object) : super(object) {
    blockType = type;
  }

  JSONBlockReader readNextBlock([Map<String, int> blockTypes]) {
    if (isEOF()) {
      return null;
    }

    var obj = Map();
    obj["container"] = this._peek();
    var type = this.readBlockType(blockTypes);
    var c = this.context.first;
    if (c is Map) {
      c.remove(this.nextKey);
    } else if (c is List) {
      c.removeAt(0);
    }

    return JSONBlockReader.fromObject(type, obj);
  }

  readBlockType(Map<String, int> blockTypes) {
    var next = this._peek();
    var bType;
    if (next is Map) {
      var c = this.context.first;
      if (c is Map) {
        bType = blockTypes[this.nextKey];
      } else if (c is List) {
        // Objects are serialized with "type" property.
        var nType = next["type"];
        bType = blockTypes[nType];
      }
    } else if (next is List) {
      // Arrays are serialized as "type": [Array].
      bType = blockTypes[this.nextKey];
    }
    return bType;
  }

  _peek() {
    var stream = this.context.first;
    var next;
    if (stream is Map) {
      next = stream[this.nextKey];
    } else if (stream is List) {
      next = stream[0];
    }
    return next;
  }

  get nextKey => this.context.first.keys.first;
}
