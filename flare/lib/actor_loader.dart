import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';
import "binary_reader.dart";

class ActorLoader
{
	void load(String filename) async
	{
		print("Loading actor filename $filename");
		ByteData data = await rootBundle.load(filename + ".nima");
		BinaryReader reader = new BinaryReader(data);
		if(data.getUint8(0) != 78 || data.getUint8(1) != 73 || data.getUint8(2) != 77 || data.getUint8(3) != 65)
		{
			print("Not nima");
		}
		else
		{
			print("Nima!");
		}
	}
}