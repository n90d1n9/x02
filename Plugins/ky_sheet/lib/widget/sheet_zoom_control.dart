import 'package:flutter/material.dart';

import '../theme/ky_sheet_theme.dart';
import 'sheet_ribbon_density.dart';

/// Compact spreadsheet zoom control for status and ribbon surfaces.
class SheetZoomControl extends StatelessWidget {
  const SheetZoomControl({
    super.key,
    required this.zoom,
    required this.onChanged,
    required this.onZoomOut,
    required this.onZoomIn,
    required this.onReset,
  });

  static const minZoom = 0.5;
  static const maxZoom = 3.0;

  final double zoom;
  final ValueChanged<double> onChanged;
  final VoidCallback onZoomOut;
  final VoidCallback onZoomIn;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final density = SheetRibbonDensityScope.of(context);
    final clampedZoom = zoom.clamp(minZoom, maxZoom).toDouble();
    final label = '${(clampedZoom * 100).round()}%';

    return Tooltip(
      message: 'Zoom $label',
      child: Semantics(
        label: 'Zoom $label',
        child: Container(
          key: const ValueKey('ky-sheet-status-zoom-control'),
          height: density.zoomControlHeight,
          padding: density.zoomControlPadding,
          decoration: BoxDecoration(
            color: KySheetColors.surfaceMuted,
            borderRadius: BorderRadius.circular(density.zoomControlRadius),
            border: Border.all(color: KySheetColors.gridLine),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ZoomIconButton(
                key: const ValueKey('ky-sheet-status-zoom-out'),
                icon: Icons.remove,
                tooltip: 'Zoom Out',
                onPressed: onZoomOut,
              ),
              SizedBox(
                width: density.zoomSliderWidth,
                height: density.zoomSliderHeight,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: density.zoomSliderTrackHeight,
                    thumbShape: RoundSliderThumbShape(
                      enabledThumbRadius: density.zoomSliderThumbRadius,
                    ),
                    overlayShape: RoundSliderOverlayShape(
                      overlayRadius: density.zoomSliderOverlayRadius,
                    ),
                  ),
                  child: Slider(
                    key: const ValueKey('ky-sheet-status-zoom-slider'),
                    min: minZoom,
                    max: maxZoom,
                    divisions: 25,
                    value: clampedZoom,
                    label: label,
                    onChanged: onChanged,
                  ),
                ),
              ),
              _ZoomIconButton(
                key: const ValueKey('ky-sheet-status-zoom-in'),
                icon: Icons.add,
                tooltip: 'Zoom In',
                onPressed: onZoomIn,
              ),
              SizedBox(width: density.zoomLabelGap),
              SizedBox(
                width: density.zoomLabelWidth,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: KySheetColors.text,
                    fontSize: density.zoomLabelFontSize,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _ZoomIconButton(
                key: const ValueKey('ky-sheet-status-zoom-reset'),
                icon: Icons.center_focus_strong,
                tooltip: 'Reset Zoom',
                onPressed: onReset,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Icon-only button used by the spreadsheet zoom control.
class _ZoomIconButton extends StatelessWidget {
  const _ZoomIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final density = SheetRibbonDensityScope.of(context);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(density.zoomButtonRadius),
        child: SizedBox(
          width: density.zoomButtonSize,
          height: density.zoomButtonSize,
          child: Icon(
            icon,
            size: density.zoomButtonIconSize,
            color: KySheetColors.text,
          ),
        ),
      ),
    );
  }
}
