import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Renders a reusable dense text input for document panel and dialog forms.
class DocumentPanelTextField extends StatelessWidget {
  final Key? fieldKey;
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final String? helperText;
  final IconData? prefixIcon;
  final String? suffixText;
  final Widget? suffixIcon;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? contentPadding;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int? minLines;
  final int? maxLines;
  final bool autofocus;
  final double borderRadius;

  const DocumentPanelTextField({
    super.key,
    this.fieldKey,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.helperText,
    this.prefixIcon,
    this.suffixText,
    this.suffixIcon,
    this.padding = EdgeInsets.zero,
    this.contentPadding,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.minLines,
    this.maxLines = 1,
    this.autofocus = false,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final field = TextField(
      key: fieldKey,
      controller: controller,
      autofocus: autofocus,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        helperMaxLines: 2,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 18),
        suffixText: suffixText,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.24),
        contentPadding:
            contentPadding ??
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
