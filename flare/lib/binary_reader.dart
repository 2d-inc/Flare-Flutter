import 'dart:typed_data';

class BinaryReader
{
	ByteData _raw;
	int _readIndex;

	BinaryReader(ByteData data)
	{
		_raw = data;
		_readIndex = 0;
	}

	double readFloat32()
	{
		double value = _raw.getFloat32(_readIndex, Endian.little);
		_readIndex += 4;
		
		return value;
	}

	Float32List readFloat32Array(Float32List list, int length, int offset)
	{
		int end = offset + length;
		for (int i = offset; i < end; i++)
		{
			list[i] = _raw.getFloat32(_readIndex, Endian.little);
			_readIndex += 4;
		}
		return list;
	}

	double readFloat64()
	{
		double value = _raw.getFloat64(_readIndex, Endian.little);
		_readIndex += 8;
			
		return value;
	}

	int readUint8()
	{
		return _raw.getUint8(_readIndex++);
	}

	bool isEOF()
	{
		return _readIndex >= _raw.lengthInBytes;
	}

	int readInt8()
	{
		return _raw.getInt8(_readIndex++);
	}

	int readUint16()
	{
		int value = _raw.getUint16(_readIndex, Endian.little);
		_readIndex += 2;
			
		return value;
	}
	
	Uint16List readUint16Array(Uint16List list, int length, int offset)
	{
		int end = offset + length;
		for (int i = offset; i < end; i++)
		{
			list[i] = _raw.getUint16(_readIndex, Endian.little);
			_readIndex += 2;
		}
		return list;
	}

	int readInt16()
	{
		int value = _raw.getInt16(_readIndex, Endian.little);
		_readIndex += 2;
			
		return value;
	}

	int readUint32()
	{
		int value = _raw.getUint32(_readIndex, Endian.little);
		_readIndex += 4;
			
		return value;
	}

	int readInt32()
	{
		int value = _raw.getInt32(_readIndex, Endian.little);
		_readIndex += 4;
			
		return value;
	}

	String readString()
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

	Uint8List readUint8Array(Uint8List list, int length, int offset)
	{
		int end = offset + length;
		for (int i = offset; i < end; i++)
		{
			list[i] = _raw.getUint8(_readIndex++);
		}
		return list;
	}
}