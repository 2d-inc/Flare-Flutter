import "binary_reader.dart";
import 'dart:typed_data';

class BlockReader extends BinaryReader
{
	int _blockType;

	BlockReader(ByteData data) : super(data)
	{
		_blockType = 0;
	}

	BlockReader.fromBlock(int type, ByteData stream) : super(stream)
	{
		_blockType = type;
	}

	int get blockType
	{
		return _blockType;
	}

	// A block is defined as a TLV with type of one byte, length of 4 bytes, and then the value following.
	BlockReader readNextBlock()
	{
		if(isEOF())
		{
			return null;
		}
		int blockType = readUint8();
		int length = readUint32();

		Uint8List buffer = new Uint8List(length);

		return new BlockReader.fromBlock(blockType, new ByteData.view(readUint8Array(buffer, buffer.length, 0).buffer));
	}
}