import 'package:flutter/material.dart';

/// Renders a reusable switch row for document panel and dialog settings.
class DocumentPanelSwitchTile extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final EdgeInsetsGeometry contentPadding;
  final bool dense;

  const DocumentPanelSwitchTile({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.contentPadding = EdgeInsets.zero,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final subtitleText = subtitle?.trim();

    return SwitchListTile(
      contentPadding: contentPadding,
      dense: dense,
      secondary: icon == null
          ? null
          : Icon(
              icon,
              color: value ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: subtitleText == null || subtitleText.isEmpty
          ? null
          : Text(
              subtitleText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
      value: value,
      onChanged: onChanged,
    );
  }
}
