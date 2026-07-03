import 'package:flutter/material.dart';

import '../../models/document_editing_mode.dart';

/// Lets users switch between editing, suggesting, and viewing document modes.
class DocumentEditingModeSwitcher extends StatelessWidget {
  static const buttonKey = ValueKey('document-editing-mode-switcher');
  static const optionPrefixKey = 'document-editing-mode-option';

  final DocumentEditingMode currentMode;
  final ValueChanged<DocumentEditingMode> onModeChanged;
  final bool showLabel;

  const DocumentEditingModeSwitcher({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<DocumentEditingMode>(
      tooltip: 'Editing mode',
      initialValue: currentMode,
      onSelected: (mode) {
        if (mode == currentMode) return;
        onModeChanged(mode);
      },
      itemBuilder: (context) => [
        for (final mode in DocumentEditingMode.values)
          PopupMenuItem(
            key: Key('$optionPrefixKey-${mode.name}'),
            value: mode,
            child: _EditingModeMenuItem(
              mode: mode,
              selected: mode == currentMode,
            ),
          ),
      ],
      child: _EditingModeButton(mode: currentMode, showLabel: showLabel),
    );
  }
}

/// Displays the current editing mode as a compact app-bar control.
class _EditingModeButton extends StatelessWidget {
  final DocumentEditingMode mode;
  final bool showLabel;

  const _EditingModeButton({required this.mode, required this.showLabel});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      key: DocumentEditingModeSwitcher.buttonKey,
      height: 36,
      padding: EdgeInsets.only(left: 10, right: showLabel ? 8 : 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.72),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(mode.icon, size: 18, color: colorScheme.onSurfaceVariant),
          if (showLabel) ...[
            const SizedBox(width: 7),
            Text(
              mode.label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
          ],
          const SizedBox(width: 2),
          Icon(
            Icons.arrow_drop_down,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

/// Renders one selectable editing mode entry in the mode switcher menu.
class _EditingModeMenuItem extends StatelessWidget {
  final DocumentEditingMode mode;
  final bool selected;

  const _EditingModeMenuItem({required this.mode, required this.selected});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = selected ? colorScheme.primary : colorScheme.onSurface;

    return Row(
      children: [
        Icon(selected ? Icons.check_circle : mode.icon, color: foreground),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mode.label,
                style: TextStyle(
                  color: foreground,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                mode.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
