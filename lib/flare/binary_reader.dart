import 'dart:typed_data';
import "stream_reader.dart";

abstract class BinaryReader implements StreamReader
{
	ByteData _raw;
	int _readIndex;

	BinaryReader(ByteData data)
	{
		_raw = data;
		_readIndex = 0;
	}

	double readFloat32([String label])
	{
		double value = _raw.getFloat32(_readIndex, Endian.little);
		_readIndex += 4;
		
		return value;
	}

	Float32List readFloat32ArrayOffset(Float32List list, int length, int offset, [String label])
	{
		int end = offset + length;
		for (int i = offset; i < end; i++)
		{
			list[i] = _raw.getFloat32(_readIndex, Endian.little);
			_readIndex += 4;
		}
		return list;
	}

	double readFloat64([String label])
	{
		double value = _raw.getFloat64(_readIndex, Endian.little);
		_readIndex += 8;
			
		return value;
	}

	int readUint8([String label])
	{
		return _raw.getUint8(_readIndex++);
	}

	bool isEOF()
	{
		return _readIndex >= _raw.lengthInBytes;
	}

	int readInt8([String label])
	{
		return _raw.getInt8(_readIndex++);
	}

	int readUint16([String label])
	{
		int value = _raw.getUint16(_readIndex, Endian.little);
		_readIndex += 2;
			
		return value;
	}
	
	Uint16List readUint16Array(Uint16List list, int length, int offset, [String label])
	{
		int end = offset + length;
		for (int i = offset; i < end; i++)
		{
			list[i] = _raw.getUint16(_readIndex, Endian.little);
			_readIndex += 2;
		}
		return list;
	}

	int readInt16([String label])
	{
		int value = _raw.getInt16(_readIndex, Endian.little);
		_readIndex += 2;
			
		return value;
	}

	int readUint32([String label])
	{
		int value = _raw.getUint32(_readIndex, Endian.little);
		_readIndex += 4;
			
		return value;
	}

	int readInt32([String label])
	{
		int value = _raw.getInt32(_readIndex, Endian.little);
		_readIndex += 4;
			
		return value;
	}

	String readString([String label])
	{
		int length = readUint32();
		int end = _readIndex + length;
		StringBuffer stringBuffer = new StringBuffer();
		
		while(_readIndex < end)
		{
			int c1 = readUint8();
			if(c1 < 128)
			{
				stringBuffer.writeCharCode(c1);
			}
			else if(c1 > 191 && c1 < 224)
			{
				int c2 = readUint8();
				stringBuffer.writeCharCode((c1 & 31) << 6 | c2 & 63);
			}
			else if (c1 > 239 && c1 < 365)
			{
				int c2 = readUint8();
				int c3 = readUint8();
				int c4 = readUint8();
				int u = ((c1 & 7) << 18 | (c2 & 63) << 12 | (c3 & 63) << 6 | c4 & 63) - 0x10000;
				stringBuffer.writeCharCode(0xD800 + (u >> 10));
				stringBuffer.writeCharCode(0xDC00 + (u & 1023));
			}
			else
			{
				int c2 = readUint8();
				int c3 = readUint8();
				stringBuffer.writeCharCode((c1 & 15) << 12 | (c2 & 63) << 6 | c3 & 63);
			}
		}

		return stringBuffer.toString();
	}

    @override
	Uint8List readUint8Array(Uint8List list, int length, int offset, [String label])
	{
		int end = offset + length;
		for (int i = offset; i < end; i++)
		{
			list[i] = _raw.getUint8(_readIndex++);
		}
		return list;
	}

    @override
    int readVersion()
    {
        return this.readUint32();
    }

    @override
    int readUint8Length() 
    {
        return readUint8();
    }

    @override
    int readUint32Length() 
    {
        return readUint32();
    }

    @override
    int readUint16Length() 
    {
        return readUint16();
    }

    @override
    int readId(String label)
    {
        return readUint16(label);
    }

    @override
	Float32List readFloat32Array(Float32List ar, String label)
    {
        return readFloat32ArrayOffset(ar, ar.length, 0, label);
    }

    @override
    bool readBool(String label)
    {
        return readUint8(label) == 1;
    }

    @override
    openArray(String label)
    {
        /* NOP */
    }

    @override
    closeArray() 
    {
        /* NOP */
    }

    @override
    openObject(String label) 
    {
        /* NOP */
    }

    @override
    closeObject() 
    {
        /* NOP */
    }

    @override
    String get containerType => "bin";
}