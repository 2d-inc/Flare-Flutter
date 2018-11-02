import "dart:math";
import "flare.dart";
import "flare/math/mat2d.dart";
import "flare/math/vec2d.dart";
import "flare/math/aabb.dart";
import "package:flutter/material.dart";
import "package:flutter/scheduler.dart";

typedef void FlareCompletedCallback(String name);

abstract class FlareController
{
    initialize(FlutterActor actor);
    setViewTransform(Mat2D viewTransform);
    advance(FlutterActor actor, double elapsed);
}

class FlareActor extends LeafRenderObjectWidget
{
    final String filename;
    final String animation;
    final BoxFit fit;
    final Alignment alignment;
    final bool isPaused;
    final bool shouldClip;
    final FlareController controller;
    final FlareCompletedCallback callback;
	final Color color;

    FlareActor(this.filename, {this.animation, this.fit = BoxFit.contain, this.alignment = Alignment.center, this.isPaused = false, this.controller, this.callback, this.color, this.shouldClip = true});

    @override
    RenderObject createRenderObject(BuildContext context)
    {
        return new FlareActorRenderObject()
                        ..filename = filename
                        ..fit = fit
                        ..alignment = alignment
                        ..animationName = animation
                        ..isPlaying = !isPaused && animation != null
                        ..controller = controller
                        ..completed = callback
						..color = color
                        ..shouldClip = shouldClip;
    }

    @override
    void updateRenderObject(BuildContext context, covariant FlareActorRenderObject renderObject)
    {
        renderObject
            ..filename = filename
            ..fit = fit
            ..alignment = alignment
            ..animationName = animation
            ..isPlaying = !isPaused && animation != null
			.. color = color
            ..shouldClip = shouldClip;
    }
}

class FlareAnimationLayer
{
    String name;
    ActorAnimation animation;
    double time = 0.0, mix = 0.0;
}

class FlareActorRenderObject extends RenderBox
{
    String _filename;
    BoxFit _fit;
    Alignment _alignment;
    String _animationName;
    FlareController _controller;
    FlareCompletedCallback _completedCallback;
	double _lastFrameTime = 0.0;
	double _mixSeconds = 0.2;

    List<FlareAnimationLayer> _animationLayers = [];
    bool _isPlaying;
    bool shouldClip;

    FlutterActor _actor;
    AABB _setupAABB;

	Color _color;

    Color get color => _color;
    set color(Color value)
    {
        if(value != _color)
        {
            _color = value;
            markNeedsPaint();
        }
    }

    BoxFit get fit => _fit;
    set fit(BoxFit value)
    {
        if(value != _fit)
        {
            _fit = value;
            markNeedsPaint();
        }
    }

    bool get isPlaying => _isPlaying;
    set isPlaying(bool value)
    {
        if(value != _isPlaying)
        {
            _isPlaying = value;
            if(_isPlaying)
            {
                SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
            }
			else
			{
				_lastFrameTime = 0;
			}
        }
    }

    String get animationName => _animationName;
    set animationName(String value)
    {
        if(value != _animationName)
        {
            _animationName = value;
            _updateAnimation();
        }
    }

    FlareController get controller => _controller;
    set controller(FlareController c)
    {
        if(_controller != c)
        {
            _controller = c;
            if(_controller != null && _actor != null)
            {
                _controller.initialize(_actor);
            }
        }
    }

    String get filename => _filename;
    set filename(String value)
    {
        if(value != _filename)
        {
            _filename = value;
            if(_actor != null)
            {
                _actor.dispose();
                _actor = null;
            }
            if(_filename == null)
            {
                markNeedsPaint();
                return;
            }

            FlutterActor actor = new FlutterActor();
            actor.loadFromBundle(_filename).then(
                (bool success) {
                    if(success)
                    {
                        _actor = actor;
						if(_actor != null)
						{
                        	_actor.advance(0.0);
                        	_setupAABB = _actor.computeAABB();
						}
                        if(_controller != null)
                        {
                            _controller.initialize(_actor);
                        }
                        _updateAnimation(onlyWhenMissing: true);
                        markNeedsPaint();
                    }
                }
            );
        }
    }

    Alignment get alignment => _alignment;
    set alignment(Alignment value)
    {
        if(value != _alignment)
        {
            _alignment = value;
            markNeedsPaint();
        }
    }

    FlareCompletedCallback get completed => _completedCallback;
    set completed(FlareCompletedCallback value)
    {
        if(_completedCallback != value)
        {
            _completedCallback = value;
        }
    }

    @override
    bool get sizedByParent => true;

    @override
    bool hitTestSelf(Offset screenOffset) => true;

    @override
    performResize()
    {
        size = constraints.biggest;
    }

    @override
    void performLayout() 
    {
        super.performLayout();
    }

    void beginFrame(Duration timestamp)
    {
        final double t = timestamp.inMicroseconds / Duration.microsecondsPerMillisecond / 1000.0;
        if(_lastFrameTime == 0 || _actor == null)
        {
            _lastFrameTime = t;
            SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
			return;
        }

        double elapsedSeconds = t - _lastFrameTime;
        _lastFrameTime = t;

        int lastFullyMixed = -1;
        double lastMix = 0.0;

        List<FlareAnimationLayer> completed = [];

        for(int i = 0; i < _animationLayers.length; i++)
        {
            FlareAnimationLayer layer = _animationLayers[i];
            layer.mix += elapsedSeconds;
            layer.time += elapsedSeconds;

            lastMix = (_mixSeconds == null || _mixSeconds == 0.0) ? 1.0 : min(1.0, layer.mix/_mixSeconds);
            if(layer.animation.isLooping)
            {
                layer.time %= layer.animation.end;
            }
            layer.animation.apply(layer.time, _actor, lastMix);
            if(lastMix == 1.0)
            {
                lastFullyMixed = i;
            }
            if(layer.time > layer.animation.end)
            {
                completed.add(layer);
            }
        }

        if(lastFullyMixed != -1)
        {
            _animationLayers.removeRange(0, lastFullyMixed);
        }
        if(animationName == null && _animationLayers.length == 1 && lastMix == 1.0)
        {
            // Remove remaining animations.
            _animationLayers.removeAt(0);
        }
        for(FlareAnimationLayer animation in completed)
        {
            _animationLayers.remove(animation);
            if(_completedCallback != null)
            {
                _completedCallback(animation.name);
            }
        }

        if(_controller != null)
        {
            _controller.advance(_actor, elapsedSeconds);
        }

		if(_animationLayers.length == 0)
		{
			isPlaying = false;
		}

        if(isPlaying)
        {
            SchedulerBinding.instance.scheduleFrameCallback(beginFrame);
        }

		if(_actor != null)
		{
        	_actor.advance(elapsedSeconds);
		}

        markNeedsPaint();
    }

    @override
    void paint(PaintingContext context, Offset offset)
    {
        final Canvas canvas = context.canvas;

        if(_actor != null)
        {
            AABB bounds = _setupAABB;
            double contentWidth = bounds[2] - bounds[0];
            double contentHeight = bounds[3] - bounds[1];
            double x = -bounds[0] - contentWidth/2.0 - (_alignment.x * contentWidth/2.0);
            double y = -bounds[1] - contentHeight/2.0 - (_alignment.y * contentHeight/2.0);

            double scaleX = 1.0, scaleY = 1.0;

            canvas.save();
            if(this.shouldClip)
            {
                canvas.clipRect(offset & size);
            }

            switch(_fit)
            {
                case BoxFit.fill:
                    scaleX = size.width / contentWidth;
                    scaleY = size.height / contentHeight;
                    break;
                case BoxFit.contain:
                    double minScale = min(size.width/contentWidth, size.height/contentHeight);
                    scaleX = scaleY = minScale;
                    break;
                case BoxFit.cover:
                    double maxScale = max(size.width/contentWidth, size.height/contentHeight);
                    scaleX = scaleY = maxScale;
                    break;
                case BoxFit.fitHeight:
                    double minScale = size.height/contentHeight;
                    scaleX = scaleY = minScale;
                    break;
                case BoxFit.fitWidth:
                    double minScale = size.width/contentWidth;
                    scaleX = scaleY = minScale;
                    break;
                case BoxFit.none:
                    scaleX = scaleY = 1.0;
                    break;
                case BoxFit.scaleDown:
                    double minScale = min(size.width/contentWidth, size.height/contentHeight);
                    scaleX = scaleY = minScale < 1.0 ? minScale : 1.0;
                    break;
            }

            if(_controller != null)
            {
                Mat2D transform = new Mat2D();
                transform[4] = offset.dx + size.width/2.0 + (_alignment.x * size.width/2.0);
                transform[5] = offset.dy + size.height/2.0 + (_alignment.y * size.height/2.0);
				Mat2D.scale(transform, transform, new Vec2D.fromValues(scaleX, scaleY));
				Mat2D center = new Mat2D();
				center[4] = x;
				center[5] = y;
				Mat2D.multiply(transform, transform, center);
				_controller.setViewTransform(transform);
            }

            canvas.translate(
                offset.dx + size.width/2.0 + (_alignment.x * size.width/2.0), 
                offset.dy + size.height/2.0 + (_alignment.y * size.height/2.0), 
            );

            canvas.scale(scaleX, scaleY);
            canvas.translate(x,y);
            _actor.draw(canvas, overrideColor:_color);
            canvas.restore();
        }
    }

    _updateAnimation({bool onlyWhenMissing = false})
    {
        if(onlyWhenMissing && _animationLayers.isNotEmpty)
        {
            return;
        }
        if(_animationName != null && _actor !=  null)
        {
            ActorAnimation animation = _actor.getAnimation(_animationName);
            _animationLayers.add(new FlareAnimationLayer()
                                        ..name = _animationName
                                        ..animation = animation
                                        ..mix = 1.0);
        }
    }
}