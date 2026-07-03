import 'package:flutter/material.dart';

/// Renders a reusable dense dropdown input for document panel forms.
class DocumentPanelDropdownField<T> extends StatelessWidget {
  final Key? fieldKey;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String labelText;
  final String? helperText;
  final IconData? prefixIcon;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const DocumentPanelDropdownField({
    super.key,
    this.fieldKey,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.labelText,
    this.helperText,
    this.prefixIcon,
    this.padding = EdgeInsets.zero,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final field = DropdownButtonFormField<T>(
      key: fieldKey ?? ValueKey<Object?>(value),
      initialValue: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: labelText,
        helperText: helperText,
        helperMaxLines: 2,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 18),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.24),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.72),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
        isDense: true,
      ),
    );

    if (padding == EdgeInsets.zero) return field;
    return Padding(padding: padding, child: field);
  }
}
