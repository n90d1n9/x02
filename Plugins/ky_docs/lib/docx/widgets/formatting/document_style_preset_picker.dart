import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import 'document_style_preset.dart';

/// Shows the current paragraph style and opens a reusable preset menu.
class DocumentStylePresetPicker extends StatefulWidget {
  static const pickerKey = ValueKey('document-style-preset-picker');
  static const optionPrefixKey = 'document-style-preset-picker-option';

  final quill.QuillController controller;
  final List<DocumentStylePreset> presets;
  final DocumentStylePresetApplier applier;
  final bool expanded;

  const DocumentStylePresetPicker({
    super.key,
    required this.controller,
    this.presets = DocumentStylePresetCatalog.presets,
    this.applier = const DocumentStylePresetApplier(),
    this.expanded = false,
  });

  static Key optionKey(DocumentStylePresetId id) {
    return Key('$optionPrefixKey-${id.name}');
  }

  @override
  State<DocumentStylePresetPicker> createState() =>
      _DocumentStylePresetPickerState();
}

/// Keeps the style picker synchronized with the editor selection.
class _DocumentStylePresetPickerState extends State<DocumentStylePresetPicker> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(DocumentStylePresetPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;

    oldWidget.controller.removeListener(_handleControllerChanged);
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activePreset = widget.applier.activePreset(
      controller: widget.controller,
      presets: widget.presets,
    );

    return PopupMenuButton<DocumentStylePresetId>(
      tooltip: 'Text style: ${activePreset.label}',
      initialValue: activePreset.id,
      onSelected: _applyPreset,
      itemBuilder: (context) => [
        for (final preset in widget.presets)
          PopupMenuItem(
            key: DocumentStylePresetPicker.optionKey(preset.id),
            value: preset.id,
            height: 58,
            child: _StylePresetMenuItem(
              preset: preset,
              selected: preset.id == activePreset.id,
            ),
          ),
      ],
      child: _StylePresetPickerButton(
        preset: activePreset,
        expanded: widget.expanded,
      ),
    );
  }

  void _applyPreset(DocumentStylePresetId id) {
    final preset = widget.presets.firstWhere(
      (preset) => preset.id == id,
      orElse: () => widget.presets.first,
    );
    widget.applier.apply(controller: widget.controller, preset: preset);
  }

  void _handleControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }
}

/// Renders the closed style picker trigger used by compact toolbars.
class _StylePresetPickerButton extends StatelessWidget {
  final DocumentStylePreset preset;
  final bool expanded;

  const _StylePresetPickerButton({
    required this.preset,
    required this.expanded,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: 'Current text style ${preset.label}',
      child: Container(
        key: DocumentStylePresetPicker.pickerKey,
        height: 42,
        width: expanded ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.72),
          ),
        ),
        child: Row(
          mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
          children: [
            _StylePresetBadge(preset: preset),
            const SizedBox(width: 9),
            Flexible(
              fit: expanded ? FlexFit.tight : FlexFit.loose,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preset.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    preset.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders one selectable paragraph style inside the preset menu.
class _StylePresetMenuItem extends StatelessWidget {
  final DocumentStylePreset preset;
  final bool selected;

  const _StylePresetMenuItem({required this.preset, required this.selected});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = selected ? colorScheme.primary : colorScheme.onSurface;

    return Row(
      children: [
        Icon(
          selected ? Icons.check_circle : preset.icon,
          size: 20,
          color: foreground,
        ),
        const SizedBox(width: 12),
        _StylePresetBadge(preset: preset, selected: selected),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                preset.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                preset.description,
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

/// Draws the compact sample badge shared by style menu rows and triggers.
class _StylePresetBadge extends StatelessWidget {
  final DocumentStylePreset preset;
  final bool selected;

  const _StylePresetBadge({required this.preset, this.selected = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = selected
        ? colorScheme.primaryContainer.withValues(alpha: 0.72)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.52);

    return Container(
      width: 32,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        preset.sampleText,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: selected
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
