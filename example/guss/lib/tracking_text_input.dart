import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:teddy/input_helper.dart';

typedef void CaretMoved(Offset globalCaretPosition);
typedef void TextChanged(String text);

// Helper widget to track caret position.
class TrackingTextInput extends StatefulWidget {
  const TrackingTextInput(
      {Key key,
      this.onCaretMoved,
      this.onTextChanged,
      this.hint,
      this.label,
      this.isObscured = false})
      : super(key: key);
  final CaretMoved onCaretMoved;
  final TextChanged onTextChanged;
  final String hint;
  final String label;
  final bool isObscured;
  @override
  _TrackingTextInputState createState() => _TrackingTextInputState();
}

class _TrackingTextInputState extends State<TrackingTextInput> {
  final GlobalKey _fieldKey = GlobalKey();
  final TextEditingController _textController = TextEditingController();
  Timer _debounceTimer;
  bool _hasFocus = false;
  @override
  void initState() {
    _textController.addListener(() {
      if (widget.onTextChanged != null) {
        widget.onTextChanged(_textController.text);
      }
      debounceUpdateCaret();
    });
    super.initState();
  }

  void debounceUpdateCaret() {
    // We debounce the listener as sometimes the caret position is updated
    // after the listener this assures us we get an accurate caret position.
    if (_debounceTimer?.isActive ?? false) _debounceTimer.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 15), updateCaret);
  }

  void updateCaret() {
    if (widget.onTextChanged != null) {
      widget.onTextChanged(_textController.text);
    }
    if (_fieldKey.currentContext != null) {
      // Find the render editable in the field.
      final RenderObject fieldBox = _fieldKey.currentContext.findRenderObject();
      Offset caretPosition =
          _hasFocus ? getCaretPosition(fieldBox as RenderBox) : null;

      if (widget.onCaretMoved != null) {
        widget.onCaretMoved(caretPosition);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Focus(
        onFocusChange: (focus) {
          _hasFocus = focus;
          debounceUpdateCaret();
        },
        child: TextFormField(
          decoration: InputDecoration(
            hintText: widget.hint,
            labelText: widget.label,
          ),
          key: _fieldKey,
          controller: _textController,
          obscureText: widget.isObscured,
        ),
      ),
    );
  }
}
