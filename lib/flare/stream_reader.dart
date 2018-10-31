import 'dart:typed_data';

import "block_reader.dart";
import "json_block_reader.dart";

abstract class StreamReader
{
    int blockType = 0;

    // Instantiate the right type of Reader based on the input values
    factory StreamReader(data)
    {
        var reader;
        if(data is ByteData)
        {
            reader = new BlockReader(data);
            // Move the readIndex forward for the binary reader.
            reader.readUint8();
            reader.readUint8();
            reader.readUint8();
            reader.readUint8();
            reader.readUint8();
        }
        else if(data is Map)
        {
            reader = new JSONBlockReader(data);
        }
        return reader;
    }

	bool isEOF();
    
	int readUint8Length();
	int readUint16Length();
    int readUint32Length();

	int readUint8(String label);
    readUint8Array(Uint8List list, int length, int offset, String label);
	int readInt8(String label);
	int readUint16(String label);
	readUint16Array(Uint16List ar, int length, int offset, String label);
	int readInt16(String label);
    int readInt32(String label);
	int readUint32(String label);
    int readVersion();
    double readFloat32(String label);
	readFloat32Array(Float32List ar, String label);
	readFloat32ArrayOffset(Float32List ar, int length, int offset, String label);
	double readFloat64(String label);

    String readString(String label);
    
    bool readBool(String label);

    int readId(String label);

    StreamReader readNextBlock(Map<String, int> types);

    openArray(String label);
    closeArray();
    openObject(String label);
    closeObject();

    String get containerType;
}