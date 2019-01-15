import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

typedef void DemoButtonSelectedCallback(int index, String item);

class DemoButtonBar extends StatelessWidget
{
	final List<String> data;
	final String selectedItem;
	final DemoButtonSelectedCallback selectedCallback;

	DemoButtonBar(this.data,
		{
			Key key,
			this.selectedItem,
			this.selectedCallback
		}): super(key: key);


	_onTapDown(BuildContext context, TapDownDetails details)
	{
		RenderObject ro = context.findRenderObject();
		if(ro is RenderBox)
		{
			Offset local = ro.globalToLocal(details.globalPosition);
			int index = (local.dx / (ro.size.width/data.length)).floor();
			if(selectedCallback != null)
			{
				selectedCallback(index, data[index]);
			}
//			print("HIT INDEX $index");
		}
	}

	@override
	Widget build(BuildContext context) 
	{
		return new GestureDetector(
			onTapDown:(TapDownDetails details) => _onTapDown(context, details),
			child:new DemoButtonBarDisplay(data, selectedItem: selectedItem));
	}
}

class DemoButtonBarDisplay extends LeafRenderObjectWidget
{
	final List<String> data;
	final String selectedItem;

	DemoButtonBarDisplay(this.data,
		{
			Key key,
			this.selectedItem,
		}): super(key: key);

	@override
	RenderObject createRenderObject(BuildContext context) 
	{
		return new DemoButtonBarRenderObject(data, selectedItem);
	}

	@override
	void updateRenderObject(BuildContext context, covariant DemoButtonBarRenderObject renderObject)
	{
		renderObject..data = data
					..selectedItem = selectedItem;
	}
}

class DataLabelParagraph
{
	String item;
	ui.Paragraph paragraph;
	Size size;
}

const double DemoButtonPadding = 20.0;
class DemoButtonBarRenderObject extends RenderBox
{
	List<String> _data;

	List<DataLabelParagraph> _labelParagraphs;
	double _fullParagraphWidth = 0.0;
	String _selectedItem;
	double _lastFrameTime = 0.0;

	double _selectedIndex = 0.0;
	double _targetSelectedIndex = 0.0;

	DemoButtonBarRenderObject(List<String> data, String selectedItem)
	{
		this.data = data;
		this.selectedItem = selectedItem;
	}
	
	void beginFrame(Duration timeStamp) 
	{
		final double t = timeStamp.inMicroseconds / Duration.microsecondsPerMillisecond / 1000.0;
		
		if(_lastFrameTime == 0)
		{
			_lastFrameTime = t;
			SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
			return;
		}

		double elapsed = t - _lastFrameTime;
		_lastFrameTime = t;
		
		_selectedIndex += (_targetSelectedIndex-_selectedIndex)*min(1.0, elapsed*15.0);
		
		markNeedsPaint();

		if((_selectedIndex - _targetSelectedIndex).abs() < 0.01)
		{
			_selectedIndex = _targetSelectedIndex;
		}
		else
		{
			SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
		}
		
	}

	@override
	bool get sizedByParent => true;
	
	@override
	bool hitTestSelf(Offset screenOffset) => true;

	@override
	void performResize() 
	{
		size = new Size(constraints.constrainWidth(), constraints.constrainHeight(40.0));
	}

	@override
	void performLayout()
	{
		super.performLayout();
		if(_data == null)
		{
			return;
		}
		_labelParagraphs = new List<DataLabelParagraph>(_data.length);

		for(int i = 0; i < _data.length; i++)
		{
			String label = _data[i];
			ui.ParagraphBuilder builder = new ui.ParagraphBuilder(new ui.ParagraphStyle(
				textAlign:TextAlign.start,
				fontFamily: "Roboto",
				fontSize: 14.0,
				fontWeight: FontWeight.w700
			))..pushStyle(new ui.TextStyle(color: _selectedItem == label ? Colors.white : const Color.fromARGB(128, 255, 255, 255)));
			builder.addText(label);
			ui.Paragraph paragraph = builder.build();
			paragraph.layout(new ui.ParagraphConstraints(width: size.width));
			List<ui.TextBox> boxes = paragraph.getBoxesForRange(0, label.length);
			DataLabelParagraph dlp = new DataLabelParagraph()
															..paragraph = paragraph
															..item = label
															..size = new Size(boxes.last.right-boxes.first.left, boxes.last.bottom - boxes.first.top);
			_labelParagraphs[i] = dlp;
		}

		_fullParagraphWidth = _labelParagraphs.fold<double>(0.0, (double width, DataLabelParagraph p)
		{
			return width + p.size.width + DemoButtonPadding*2.0;
		});
	}
	
	@override
	void paint(PaintingContext context, Offset offset)
	{
		final Canvas canvas = context.canvas;
		canvas.drawRRect(new RRect.fromRectAndRadius(offset & size, const Radius.circular(20.0)), new ui.Paint()..color = const Color.fromARGB(77, 0, 0, 0));
		if(_data == null)
		{
			return;
		}
		double spacing = size.width - _fullParagraphWidth;
		spacing /= max(1, _data.length-1);

		double x = offset.dx;
		const double edgePadding = 2.0;

		List<Offset> xs = new List<Offset>();
		for(DataLabelParagraph p in _labelParagraphs)
		{
			xs.add(new Offset(x+edgePadding, p.size.width+DemoButtonPadding*2-edgePadding*2));
			x += p.size.width + spacing + DemoButtonPadding*2;
		}

		int index = _selectedIndex.truncate();
		double fraction = _selectedIndex - index;
		Offset from = xs[index];
		Offset to = index + 1 < xs.length ? xs[index+1] : from;
		double dx = ui.lerpDouble(from.dx, to.dx, fraction);
		double width = ui.lerpDouble(from.dy, to.dy, fraction);
		canvas.drawRRect(new RRect.fromRectAndRadius(new Offset(dx, offset.dy + edgePadding) & new Size(width, size.height-edgePadding*2), const Radius.circular(20.0)), new ui.Paint()..color = const Color.fromARGB(255, 87, 165, 244));

		x = offset.dx;
		for(DataLabelParagraph p in _labelParagraphs)
		{
			canvas.drawParagraph(p.paragraph, new Offset(x+DemoButtonPadding, offset.dy + size.height/2.0 - p.size.height/2.0));
			x += p.size.width + spacing + DemoButtonPadding*2;
		}
	}

	List<String> get data
	{
		return _data;
	}

	set data(List<String> v)
	{
		if(_data == v)
		{
			return;
		}
		_data = v;

		markNeedsLayout();
		markNeedsPaint();
	}

	String get selectedItem
	{
		return _selectedItem;
	}

	set selectedItem(String v)
	{
		if(_selectedItem == v)
		{
			return;
		}
		_selectedItem = v;
		_targetSelectedIndex = _data.indexOf(v).toDouble();
		_lastFrameTime = 0.0;
		SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
		markNeedsLayout();
		markNeedsPaint();
	}
}