library pinput;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinPut extends StatefulWidget {
  const PinPut({Key key, this.onSubmit, this.textColor});
  final Color textColor;
  final ValueChanged<String> onSubmit;
  @override
  PinPutState createState() => PinPutState();
}

class PinPutState extends State<PinPut>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  FocusNode _focusNode;
  TextEditingController _controller;
  ValueNotifier<String> _textControllerValue;
  int get selectedIndex => _controller.value.text.length;
  Animation _cursorAnimation;
  AnimationController _cursorAnimationController;
  String otpCode;
  int fieldsCount = 6;
  TextStyle textStyle;
  double eachFieldWidth = 40.0;
  double eachFieldHeight = 55.0;

  @override
  void initState() {
    textStyle = TextStyle(fontSize: 25.0, color: widget.textColor);
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _textControllerValue = ValueNotifier<String>(_controller.value.text);
    _controller?.addListener(_textChangeListener);
    configureCursor();
    super.initState();
  }

  configureCursor() {
    _cursorAnimationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _cursorAnimation = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        curve: Curves.linear, parent: _cursorAnimationController));

    _cursorAnimationController.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        _cursorAnimationController.repeat(reverse: true);
      }
    });
    _cursorAnimationController.forward();
  }

  void _textChangeListener() {
    final pin = _controller.value.text;
    if (pin != _textControllerValue.value) {
      try {
        _textControllerValue.value = pin;
      } catch (e) {
        _textControllerValue = ValueNotifier(_controller.value.text);
      }
      if (pin.length == fieldsCount) widget.onSubmit?.call(pin);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _cursorAnimationController?.dispose();
    _textControllerValue?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        _hiddenTextField,
        _fields,
      ],
    );
  }

  void _handleTap() {
    final currentFocus = FocusScope.of(context);
    if (!_focusNode.hasPrimaryFocus) {
      Future.delayed(
          Duration.zero, () => currentFocus.requestFocus(_focusNode));
    }
  }

  Widget get _hiddenTextField {
    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      enableSuggestions: false,
      autocorrect: false,
      keyboardType: TextInputType.number,
      enableInteractiveSelection: false,
      maxLength: fieldsCount,
      showCursor: false,
      scrollPadding: EdgeInsets.zero,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        counterText: '',
      ),
      style: TextStyle(color: Colors.transparent),
    );
  }

  Widget get _fields {
    return ValueListenableBuilder<String>(
      valueListenable: _textControllerValue,
      builder: (_, __, ___) {
        return GestureDetector(
          onTap: _handleTap,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: Iterable<int>.generate(fieldsCount)
                .map((index) => _getField(index))
                .toList(),
          ),
        );
      },
    );
  }

  Widget _getField(int index) {
    final String pin = _controller.value.text;
    return AnimatedContainer(
      width: eachFieldWidth,
      height: eachFieldHeight,
      alignment: Alignment.center,
      duration: const Duration(milliseconds: 160),
      curve: Curves.linear,
      constraints: const BoxConstraints(minHeight: 40.0, minWidth: 40.0),
      decoration: _fieldDecoration(index),
      child: AnimatedSwitcher(
        switchInCurve: Curves.linear,
        switchOutCurve: Curves.linear,
        duration: const Duration(milliseconds: 160),
        transitionBuilder: (child, animation) {
          return _getTransition(child, animation);
        },
        child: _buildFieldContent(index, pin),
      ),
    );
  }

  Widget _buildFieldContent(int index, String pin) {
    if (index < pin.length) {
      return Text(
        pin[index],
        key: ValueKey<String>(index < pin.length ? pin[index] : ''),
        style: textStyle,
      );
    }
    if (_focusNode.hasFocus && index == pin.length) {
      return _buildCursor();
    }
    return Text(
      '',
      key: ValueKey<String>(index < pin.length ? pin[index] : ''),
      style: textStyle,
    );
  }

  BoxDecoration _fieldDecoration(int index) {
    if (index == selectedIndex && _focusNode.hasFocus) {
      return BoxDecoration(
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(color: Color(0XFFC46C71), width: 2),
      );
    }
    return BoxDecoration(
      borderRadius: BorderRadius.circular(5.0),
      border: Border.all(
        color: Colors.grey,
      ),
    );
  }

  Widget _getTransition(Widget child, Animation animation) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  Widget _buildCursor() {
    return AnimatedBuilder(
      animation: _cursorAnimationController,
      builder: (context, child) {
        return Center(
          child: Opacity(
            opacity: _cursorAnimation.value,
            child: Text('|', style: textStyle),
          ),
        );
      },
    );
  }
}
