import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PropertyNumberField extends StatefulWidget {
  final String label;
  final double value;
  final bool enabled;
  final ValueChanged<double> onSubmitted;

  const PropertyNumberField({
    super.key,
    required this.label,
    required this.value,
    required this.onSubmitted,
    this.enabled = true,
  });

  @override
  State<PropertyNumberField> createState() => _PropertyNumberFieldState();
}

class _PropertyNumberFieldState extends State<PropertyNumberField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _format(widget.value));
  }

  @override
  void didUpdateWidget(PropertyNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextText = _format(widget.value);
    if (oldWidget.value == widget.value || _controller.text == nextText) {
      return;
    }

    _controller.text = nextText;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      enabled: widget.enabled,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d{0,2}')),
      ],
      textInputAction: TextInputAction.done,
      onSubmitted: (value) {
        final parsed = double.tryParse(value);
        if (parsed == null) {
          _controller.text = _format(widget.value);
          return;
        }

        widget.onSubmitted(parsed);
      },
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.045),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: Color(0xFF6366F1)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
    );
  }

  String _format(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }
}
