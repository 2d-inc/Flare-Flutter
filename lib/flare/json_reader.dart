import "dart:collection";
import "dart:typed_data";

import "stream_reader.dart";

abstract class JSONReader implements StreamReader
{
    @override
    int blockType;

    dynamic _readObject;
    ListQueue _context;

	JSONReader(Map object)
	{
		_readObject = object["container"];
		_context = new ListQueue();
        _context.addFirst(_readObject);
	}

    dynamic readProp(String label)
    {
		var head = _context.first;
		if(head is Map)
		{
			var prop = head[label];
            head.remove(label);
			return prop;
		}
		else if(head is List)
		{
			return head.removeAt(0);
		}
        return null;
	}

    @override
	readFloat32(label)
	{
        num f = this.readProp(label);
        return f.toDouble();
	}
	
	// Reads the array into ar
    @override
	readFloat32Array(Float32List ar, String label)
	{
		this._readArray(ar, label);
	}

    @override
	readFloat32ArrayOffset(Float32List ar, int length, int offset, String label)
	{
		this._readArrayOffset(ar, length, offset, label);
	}

    _readArrayOffset(List ar, int length, int offset, String label)
    {
        List array = this.readProp(label);
        num listElement = ar.first;
        for(int i = 0; i < length; i++)
        {
            num val = array[i];
            ar[offset + i] = listElement is double ? val.toDouble() : val.toInt();
        }
    }

	_readArray(List ar, String label)
	{
		List array = this.readProp(label);
		for (int i = 0; i < ar.length; i++)
		{
            num val = array[i];
			ar[i] = ar.first is double ? val.toDouble() : val.toInt();
		}
	}

    @override
	readFloat64(label)
	{
        num f = this.readProp(label);
        return f.toDouble();
    }

	@override
	readUint8(label)
	{
        return this.readProp(label);
	}

	@override
	readUint8Length()
	{
		return this._readLength();
	}

	@override
	bool isEOF()
	{
		return _context.length <= 1 && _readObject.length == 0;
	}

	@override
	readInt8(label)
	{
        return this.readProp(label);
    }

	@override
	readUint16(label)
	{
        return this.readProp(label);
    }

    @override
	readUint8Array(Uint8List ar, int length, int offset, String label)
	{
		return this._readArrayOffset(ar, length, offset, label);
	}

    @override
	readUint16Array(Uint16List ar, int length, int offset, String label)
	{
		return this._readArrayOffset(ar, length, offset, label);
	}

	@override
	readInt16(label)
	{
        return this.readProp(label);
	}

	@override
	readUint16Length()
	{
		return this._readLength();
	}

	@override
	readUint32Length()
	{
		return this._readLength();
	}

	@override
	readUint32(label)
	{
        return this.readProp(label);
    }
	
    @override
	readInt32(label)
	{
        return this.readProp(label);
    }

    @override
    int readVersion()
    {
        return this.readProp("version");
    }

	@override
	readString(label)
	{
        return this.readProp(label);
	}
	
    @override
	readBool(String label)
	{
		return this.readProp(label);
	}


    // @hasOffset flag is needed for older (up until version 14) files.
    // Since the JSON Reader has been added in version 15, the field here is optional.
	@override
	readId(String label)
	{
		var val = this.readProp(label);
		return val is num ? val+1 : 0;
	}

	@override
	openArray(label)
	{
		var array = this.readProp(label);
        _context.addFirst(array);
	}

	@override
	closeArray()
	{
		_context.removeFirst();
	}

	@override
	openObject(label)
	{
		var o = this.readProp(label);
		_context.addFirst(o);
	}

	@override
	closeObject()
	{
		this._context.removeFirst();
	}

	int _readLength() => _context.first.length; // Maps and Lists both have a `length` property.
    @override
    String get containerType => "json";
    ListQueue get context => _context;
}