import 'package:flutter/material.dart';

class PropertyMultilineField extends StatefulWidget {
  final String label;
  final String value;
  final bool enabled;
  final int minLines;
  final int maxLines;
  final ValueChanged<String> onSubmitted;

  const PropertyMultilineField({
    super.key,
    required this.label,
    required this.value,
    required this.onSubmitted,
    this.enabled = true,
    this.minLines = 4,
    this.maxLines = 6,
  });

  @override
  State<PropertyMultilineField> createState() => _PropertyMultilineFieldState();
}

class _PropertyMultilineFieldState extends State<PropertyMultilineField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(PropertyMultilineField oldWidget) {
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
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.35),
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.done,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        alignLabelWithHint: true,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.045),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 12,
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
}
