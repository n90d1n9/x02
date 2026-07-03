import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/sheet_view_state.dart';
import '../state/spreadsheet_provider.dart';
import '../state/toolbar_provider.dart';
import '../theme/ky_sheet_theme.dart';

class SheetViewPanel extends ConsumerWidget {
  const SheetViewPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(selectedCellProvider);
    final freezePane = ref.watch(freezePanesProvider);
    final zoom = ref.watch(zoomLevelProvider);
    final controller = ref.watch(toolbarControllerProvider);
    final summary = SheetViewStateSummary(freezePane: freezePane, zoom: zoom);

    return Container(
      width: 306,
      decoration: const BoxDecoration(
        color: KySheetColors.surface,
        border: Border(left: BorderSide(color: KySheetColors.gridLine)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PanelHeader(),
          const Divider(height: 1, color: KySheetColors.gridLine),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _StatusBand(
                  icon: Icons.splitscreen,
                  label: summary.freezeLabel,
                  detail: summary.freezeDetail,
                ),
                const SizedBox(height: 18),
                _SectionLabel(
                  icon: Icons.view_week_outlined,
                  label: 'Freeze Panes',
                  detail: summary.hasFreeze ? 'Active' : 'Off',
                ),
                const SizedBox(height: 10),
                _CommandGrid(
                  children: [
                    _ViewCommandButton(
                      key: const ValueKey('ky-sheet-view-freeze-first-row'),
                      icon: Icons.table_rows,
                      label: 'First Row',
                      selected:
                          summary.frozenRowCount == 1 &&
                          summary.frozenColumnCount == 0,
                      onPressed: controller.freezeFirstRow,
                    ),
                    _ViewCommandButton(
                      key: const ValueKey('ky-sheet-view-freeze-first-column'),
                      icon: Icons.view_column_outlined,
                      label: 'First Column',
                      selected:
                          summary.frozenRowCount == 0 &&
                          summary.frozenColumnCount == 1,
                      onPressed: controller.freezeFirstColumn,
                    ),
                    _ViewCommandButton(
                      key: const ValueKey(
                        'ky-sheet-view-freeze-first-row-column',
                      ),
                      icon: Icons.grid_view,
                      label: 'Row + Column',
                      selected:
                          summary.frozenRowCount == 1 &&
                          summary.frozenColumnCount == 1,
                      onPressed: controller.freezeFirstRowAndColumn,
                    ),
                    _ViewCommandButton(
                      key: const ValueKey('ky-sheet-view-freeze-selection'),
                      icon: Icons.my_location,
                      label: 'Selection',
                      selected:
                          selection != null &&
                          freezePane == selection.start &&
                          summary.hasFreeze,
                      onPressed: selection == null
                          ? null
                          : () => controller.freezePanesAt(selection),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  key: const ValueKey('ky-sheet-view-unfreeze'),
                  onPressed: summary.hasFreeze
                      ? controller.unfreezePanes
                      : null,
                  icon: const Icon(Icons.lock_open, size: 18),
                  label: const Text('Unfreeze Panes'),
                ),
                const SizedBox(height: 18),
                _SectionLabel(
                  icon: Icons.zoom_in,
                  label: 'Zoom',
                  detail: summary.zoomLabel,
                ),
                const SizedBox(height: 8),
                _ZoomControls(
                  zoom: zoom,
                  onChanged: controller.setZoom,
                  onZoomOut: controller.zoomOut,
                  onZoomIn: controller.zoomIn,
                  onReset: controller.resetZoom,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Row(
        children: [
          Icon(
            Icons.visibility_outlined,
            color: KySheetColors.accent,
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sheet View',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBand extends StatelessWidget {
  const _StatusBand({
    required this.icon,
    required this.label,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KySheetColors.accentSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: KySheetColors.gridLine),
      ),
      child: Row(
        children: [
          Icon(icon, color: KySheetColors.accent, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: KySheetColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.label,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: KySheetColors.mutedText, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
        ),
        Text(
          detail,
          style: const TextStyle(
            color: KySheetColors.mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CommandGrid extends StatelessWidget {
  const _CommandGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, height: 68, child: child),
          ],
        );
      },
    );
  }
}

class _ViewCommandButton extends StatelessWidget {
  const _ViewCommandButton({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : KySheetColors.text;
    final background = selected
        ? KySheetColors.accent
        : KySheetColors.surfaceMuted;

    return Tooltip(
      message: label,
      child: FilledButton.tonal(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          foregroundColor: foreground,
          backgroundColor: background,
          disabledForegroundColor: KySheetColors.mutedText.withValues(
            alpha: 0.45,
          ),
          disabledBackgroundColor: KySheetColors.surfaceMuted.withValues(
            alpha: 0.7,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 19),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomControls extends StatelessWidget {
  const _ZoomControls({
    required this.zoom,
    required this.onChanged,
    required this.onZoomOut,
    required this.onZoomIn,
    required this.onReset,
  });

  final double zoom;
  final ValueChanged<double> onChanged;
  final VoidCallback onZoomOut;
  final VoidCallback onZoomIn;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: KySheetColors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: KySheetColors.gridLine),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: onZoomOut,
                icon: const Icon(Icons.zoom_out, size: 18),
                tooltip: 'Zoom Out',
              ),
              Expanded(
                child: Slider(
                  key: const ValueKey('ky-sheet-view-zoom-slider'),
                  min: 0.5,
                  max: 3.0,
                  divisions: 10,
                  value: zoom.clamp(0.5, 3.0),
                  label: '${(zoom * 100).round()}%',
                  onChanged: onChanged,
                ),
              ),
              IconButton.filledTonal(
                onPressed: onZoomIn,
                icon: const Icon(Icons.zoom_in, size: 18),
                tooltip: 'Zoom In',
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const ValueKey('ky-sheet-view-reset-zoom'),
              onPressed: onReset,
              icon: const Icon(Icons.center_focus_strong, size: 18),
              label: const Text('Reset Zoom'),
            ),
          ),
        ],
      ),
    );
  }
}
