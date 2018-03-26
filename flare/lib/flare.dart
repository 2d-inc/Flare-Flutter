library flare;

import "dart:async";
import "dart:typed_data";
import "actor.dart";
//import "dart:ui" as ui;
import "package:flutter/services.dart" show rootBundle;

class FlutterActor extends Actor
{
	Future<bool> loadFromBundle(String filename) async
	{
		print("Loading actor filename $filename");
		ByteData data = await rootBundle.load(filename + ".flr");
		super.load(data);

		// List<Future<ui.Codec>> waitList = new List<Future<ui.Codec>>();
		// _images = new List<ui.Image>(texturesUsed);

		// for(int i = 0; i < texturesUsed; i++)
		// {
		// 	String atlasFilename;
		// 	if(texturesUsed == 1)
		// 	{
		// 		atlasFilename = filename + ".png";
		// 	}
		// 	else
		// 	{
		// 		atlasFilename = filename + i.toString() + ".png";
		// 	}
		// 	ByteData data = await rootBundle.load(atlasFilename);
		// 	Uint8List list = new Uint8List.view(data.buffer);
		// 	waitList.add(ui.instantiateImageCodec(list));
		// }

		// List<ui.Codec> codecs = await Future.wait(waitList);
		// List<ui.FrameInfo> frames = await Future.wait(codecs.map((codec) => codec.getNextFrame()));
		// for(int i = 0; i < frames.length; i++)
		// {
		// 	_images[i] = frames[i].image;
		// }

		// for(FlutterActorImage image in imageNodes)
		// {
		// 	image.init();
		// }

		return true;
	}
}