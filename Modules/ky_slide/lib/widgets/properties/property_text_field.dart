import 'package:flutter/material.dart';

class PropertyTextField extends StatefulWidget {
  final String label;
  final String value;
  final bool enabled;
  final ValueChanged<String> onSubmitted;

  const PropertyTextField({
    super.key,
    required this.label,
    required this.value,
    required this.onSubmitted,
    this.enabled = true,
  });

  @override
  State<PropertyTextField> createState() => _PropertyTextFieldState();
}

class _PropertyTextFieldState extends State<PropertyTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(PropertyTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value || _controller.text == widget.value) {
      return;
    }

    _controller.text = widget.value;
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
      textInputAction: TextInputAction.done,
      onSubmitted: widget.onSubmitted,
      decoration: _inputDecoration(widget.label),
    );
  }
}

InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.045),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
  );
}
