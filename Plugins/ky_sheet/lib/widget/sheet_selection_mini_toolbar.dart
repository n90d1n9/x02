import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/cell/cell_selection.dart';
import '../state/sheet_format_painter_provider.dart';
import '../state/sheet_sidebar_provider.dart';
import '../state/toolbar_provider.dart';
import '../theme/ky_sheet_theme.dart';

class SheetSelectionMiniToolbar extends ConsumerWidget {
  const SheetSelectionMiniToolbar({super.key, required this.selection});

  final CellSelection selection;

  static const height = 44.0;
  static const maxWidth = 352.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolbar = ref.read(toolbarControllerProvider);
    final formatPainterActive =
        ref.watch(sheetFormatPainterSnapshotProvider) != null;

    return Material(
      key: const ValueKey('ky-sheet-mini-toolbar'),
      color: KySheetColors.surface,
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: KySheetColors.gridLineStrong),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SizedBox(
          height: height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MiniToolbarButton(
                    key: const ValueKey('ky-sheet-mini-bold'),
                    icon: Icons.format_bold,
                    tooltip: 'Bold',
                    onPressed: () => toolbar.toggleBold(selection),
                  ),
                  _MiniToolbarButton(
                    key: const ValueKey('ky-sheet-mini-italic'),
                    icon: Icons.format_italic,
                    tooltip: 'Italic',
                    onPressed: () => toolbar.toggleItalic(selection),
                  ),
                  _MiniToolbarButton(
                    key: const ValueKey('ky-sheet-mini-underline'),
                    icon: Icons.format_underlined,
                    tooltip: 'Underline',
                    onPressed: () => toolbar.toggleUnderline(selection),
                  ),
                  _MiniToolbarColorMenu(
                    key: const ValueKey('ky-sheet-mini-fill'),
                    icon: Icons.format_color_fill,
                    tooltip: 'Fill Color',
                    colors: _fillColors,
                    onSelected: (color) =>
                        toolbar.setBackground(selection, color),
                  ),
                  _MiniToolbarColorMenu(
                    key: const ValueKey('ky-sheet-mini-text-color'),
                    icon: Icons.format_color_text,
                    tooltip: 'Text Color',
                    colors: _textColors,
                    onSelected: (color) =>
                        toolbar.setTextColor(selection, color),
                  ),
                  const _MiniToolbarDivider(),
                  _MiniToolbarButton(
                    key: const ValueKey('ky-sheet-mini-format-painter'),
                    icon: Icons.format_paint_outlined,
                    tooltip: formatPainterActive
                        ? 'Cancel Format Painter'
                        : 'Format Painter',
                    selected: formatPainterActive,
                    onPressed: () => _toggleFormatPainter(ref),
                  ),
                  _MiniToolbarButton(
                    key: const ValueKey('ky-sheet-mini-inspector'),
                    icon: Icons.comment_outlined,
                    tooltip: 'Open Inspector',
                    onPressed: () =>
                        _openPanel(ref, SheetSidebarPanel.cellInspector),
                  ),
                  _MiniToolbarButton(
                    key: const ValueKey('ky-sheet-mini-chart'),
                    icon: Icons.insert_chart_outlined,
                    tooltip: 'Chart Builder',
                    onPressed: () =>
                        _openPanel(ref, SheetSidebarPanel.chartBuilder),
                  ),
                  _MiniToolbarButton(
                    key: const ValueKey('ky-sheet-mini-validation'),
                    icon: Icons.rule,
                    tooltip: 'Data Validation',
                    onPressed: () =>
                        _openPanel(ref, SheetSidebarPanel.dataValidation),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggleFormatPainter(WidgetRef ref) {
    final controller = ref.read(sheetFormatPainterControllerProvider);
    if (controller.isActive) {
      controller.cancel();
      return;
    }

    controller.start(selection);
  }

  void _openPanel(WidgetRef ref, SheetSidebarPanel panel) {
    ref.read(activeSidebarPanelProvider.notifier).state = panel;
  }
}

const _fillColors = <_MiniToolbarColorOption>[
  _MiniToolbarColorOption('Yellow', Color(0xFFFEF3C7)),
  _MiniToolbarColorOption('Green', Color(0xFFDCFCE7)),
  _MiniToolbarColorOption('Blue', Color(0xFFDBEAFE)),
  _MiniToolbarColorOption('Red', Color(0xFFFEE2E2)),
  _MiniToolbarColorOption('White', Colors.white),
];

const _textColors = <_MiniToolbarColorOption>[
  _MiniToolbarColorOption('Black', Color(0xFF111827)),
  _MiniToolbarColorOption('Red', Color(0xFFDC2626)),
  _MiniToolbarColorOption('Blue', Color(0xFF2563EB)),
  _MiniToolbarColorOption('Green', Color(0xFF16A34A)),
];

class _MiniToolbarButton extends StatelessWidget {
  const _MiniToolbarButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selected = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? KySheetColors.accent : KySheetColors.text;
    final background = selected ? KySheetColors.accentSoft : Colors.transparent;

    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 32,
            height: 32,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 18, color: foreground),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniToolbarColorMenu extends StatelessWidget {
  const _MiniToolbarColorMenu({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.colors,
    required this.onSelected,
  });

  final IconData icon;
  final String tooltip;
  final List<_MiniToolbarColorOption> colors;
  final ValueChanged<Color> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_MiniToolbarColorOption>(
      tooltip: tooltip,
      onSelected: (option) => onSelected(option.color),
      itemBuilder: (context) => [
        for (final option in colors)
          PopupMenuItem(
            value: option,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: option.color,
                    border: Border.all(color: KySheetColors.gridLineStrong),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const SizedBox(width: 18, height: 18),
                ),
                const SizedBox(width: 10),
                Text(option.label),
              ],
            ),
          ),
      ],
      child: Tooltip(
        message: tooltip,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: SizedBox(
            width: 32,
            height: 32,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 18, color: KySheetColors.text),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniToolbarDivider extends StatelessWidget {
  const _MiniToolbarDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      color: KySheetColors.gridLine,
    );
  }
}

class _MiniToolbarColorOption {
  const _MiniToolbarColorOption(this.label, this.color);

  final String label;
  final Color color;
}
