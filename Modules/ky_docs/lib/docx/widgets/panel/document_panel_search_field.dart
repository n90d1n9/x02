import 'package:flutter/material.dart';

/// Defines the background treatment used by panel-level search fields.
enum DocumentPanelSearchFieldTone { surface, container }

/// Provides a reusable search field for document side panels and rails.
class DocumentPanelSearchField extends StatelessWidget {
  final Key? fieldKey;
  final Key? clearButtonKey;
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool? hasQuery;
  final String clearTooltip;
  final DocumentPanelSearchFieldTone tone;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? contentPadding;
  final double? height;
  final double borderRadius;
  final bool autofocus;

  const DocumentPanelSearchField({
    super.key,
    this.fieldKey,
    this.clearButtonKey,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
    this.hasQuery,
    this.clearTooltip = 'Clear search',
    this.tone = DocumentPanelSearchFieldTone.surface,
    this.padding = EdgeInsets.zero,
    this.contentPadding,
    this.height,
    this.borderRadius = 8,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final searchField = TextField(
      key: fieldKey,
      controller: controller,
      autofocus: autofocus,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search, size: 18),
        suffixIcon: _showsClearButton
            ? IconButton(
                key: clearButtonKey,
                tooltip: clearTooltip,
                icon: const Icon(Icons.close, size: 18),
                onPressed: onClear,
              )
            : null,
        filled: true,
        fillColor: _fillColor(colorScheme),
        contentPadding: contentPadding,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.72),
          ),
        ),
        isDense: true,
      ),
    );

    final sizedField = height == null
        ? searchField
        : SizedBox(height: height, child: searchField);

    if (padding == EdgeInsets.zero) return sizedField;
    return Padding(padding: padding, child: sizedField);
  }

  bool get _showsClearButton => hasQuery ?? controller.text.trim().isNotEmpty;

  Color _fillColor(ColorScheme colorScheme) {
    return switch (tone) {
      DocumentPanelSearchFieldTone.surface => colorScheme.surface.withValues(
        alpha: 0.72,
      ),
      DocumentPanelSearchFieldTone.container =>
        colorScheme.surfaceContainerHighest.withValues(alpha: 0.34),
    };
  }
}
