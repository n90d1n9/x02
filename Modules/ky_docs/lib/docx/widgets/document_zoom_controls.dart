import 'package:flutter/material.dart';

/// Provides compact document zoom controls for editor chrome and status bars.
class DocumentZoomControls extends StatelessWidget {
  static const sliderKey = ValueKey('document-zoom-controls-slider');
  static const defaultMinZoom = 0.5;
  static const defaultMaxZoom = 1.5;

  final double zoom;
  final double minZoom;
  final double maxZoom;
  final VoidCallback? onZoomOut;
  final VoidCallback? onZoomIn;
  final VoidCallback? onResetZoom;
  final ValueChanged<double>? onZoomChanged;
  final bool showSlider;

  const DocumentZoomControls({
    super.key,
    required this.zoom,
    this.minZoom = defaultMinZoom,
    this.maxZoom = defaultMaxZoom,
    this.onZoomOut,
    this.onZoomIn,
    this.onResetZoom,
    this.onZoomChanged,
    this.showSlider = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final percent = (zoom * 100).round();

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.72),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.72),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ZoomIconButton(
            tooltip: 'Zoom out',
            icon: Icons.remove,
            onPressed: _canZoomOut ? onZoomOut : null,
          ),
          Tooltip(
            message: 'Reset zoom',
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: onResetZoom,
              child: SizedBox(
                width: 46,
                child: Text(
                  '$percent%',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
          if (showSlider) ...[
            const SizedBox(width: 4),
            _ZoomSlider(
              zoom: zoom,
              minZoom: minZoom,
              maxZoom: maxZoom,
              onZoomChanged: onZoomChanged,
            ),
          ],
          _ZoomIconButton(
            tooltip: 'Zoom in',
            icon: Icons.add,
            onPressed: _canZoomIn ? onZoomIn : null,
          ),
        ],
      ),
    );
  }

  bool get _canZoomOut {
    return onZoomOut != null && zoom > minZoom + 0.001;
  }

  bool get _canZoomIn {
    return onZoomIn != null && zoom < maxZoom - 0.001;
  }
}

/// Allows direct zoom selection from the editor status bar.
class _ZoomSlider extends StatelessWidget {
  final double zoom;
  final double minZoom;
  final double maxZoom;
  final ValueChanged<double>? onZoomChanged;

  const _ZoomSlider({
    required this.zoom,
    required this.minZoom,
    required this.maxZoom,
    required this.onZoomChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
      ),
      child: SizedBox(
        width: 96,
        height: 26,
        child: Slider(
          key: DocumentZoomControls.sliderKey,
          min: minZoom,
          max: maxZoom,
          divisions: ((maxZoom - minZoom) / 0.05).round(),
          value: zoom.clamp(minZoom, maxZoom).toDouble(),
          onChanged: onZoomChanged,
        ),
      ),
    );
  }
}

class _ZoomIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  const _ZoomIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon, size: 15),
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 28, height: 26),
      padding: EdgeInsets.zero,
      onPressed: onPressed,
    );
  }
}
