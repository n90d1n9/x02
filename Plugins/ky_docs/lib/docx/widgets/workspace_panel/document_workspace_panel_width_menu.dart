import 'package:flutter/material.dart';

import 'document_workspace_panel_width_preset.dart';

/// Renders a compact preset menu for snapping the utility dock width.
class DocumentWorkspacePanelWidthMenu extends StatelessWidget {
  static const buttonKey = ValueKey('document-workspace-panel-width-menu');
  static const optionPrefixKey = 'document-workspace-panel-width-option';

  final double currentWidth;
  final ValueChanged<double> onWidthChanged;

  const DocumentWorkspacePanelWidthMenu({
    super.key,
    required this.currentWidth,
    required this.onWidthChanged,
  });

  static Key optionKey(DocumentWorkspacePanelWidthPreset preset) {
    return Key('$optionPrefixKey-${preset.name}');
  }

  @override
  Widget build(BuildContext context) {
    final activePreset = DocumentWorkspacePanelWidthPreset.closestTo(
      currentWidth,
    );

    return PopupMenuButton<DocumentWorkspacePanelWidthPreset>(
      key: buttonKey,
      tooltip: 'Panel width',
      initialValue: activePreset,
      icon: Icon(activePreset.icon),
      style: IconButton.styleFrom(
        minimumSize: const Size.square(34),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      onSelected: (preset) {
        if (preset == activePreset) return;
        onWidthChanged(DocumentWorkspacePanelWidthScale.clamp(preset.width));
      },
      itemBuilder: (context) => [
        for (final preset in DocumentWorkspacePanelWidthPreset.values)
          PopupMenuItem(
            key: optionKey(preset),
            value: preset,
            child: _WidthPresetMenuItem(
              preset: preset,
              selected: preset == activePreset,
            ),
          ),
      ],
    );
  }
}

/// Shows one dock width preset with a short ergonomic hint.
class _WidthPresetMenuItem extends StatelessWidget {
  final DocumentWorkspacePanelWidthPreset preset;
  final bool selected;

  const _WidthPresetMenuItem({required this.preset, required this.selected});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = selected ? colorScheme.primary : colorScheme.onSurface;

    return Row(
      children: [
        Icon(selected ? Icons.check_circle : preset.icon, color: foreground),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                preset.label,
                style: TextStyle(
                  color: foreground,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                ),
              ),
              Text(
                preset.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
