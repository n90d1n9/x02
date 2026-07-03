import 'package:flutter/material.dart';

class PropertySelectField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> options;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onChanged;

  const PropertySelectField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.labelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: options.map((option) {
        return DropdownMenuItem<T>(
          value: option,
          child: Text(labelBuilder(option)),
        );
      }).toList(),
      dropdownColor: const Color(0xFF1E293B),
      iconEnabledColor: Colors.white54,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      onChanged: (value) {
        if (value == null) return;
        onChanged(value);
      },
      decoration: InputDecoration(
        labelText: label,
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
      ),
    );
  }
}
