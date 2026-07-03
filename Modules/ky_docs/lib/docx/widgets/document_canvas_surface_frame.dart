import 'package:flutter/material.dart';

import '../models/page_layout.dart';

/// Frames the editor canvas with page styling, focus affordance, and layout status.
class DocumentCanvasSurfaceFrame extends StatelessWidget {
  static const frameKey = ValueKey('document-canvas-surface-frame');
  static const layoutBadgeKey = ValueKey('document-canvas-layout-badge');

  final PageLayout layout;
  final double zoom;
  final bool isCompact;
  final Widget child;

  const DocumentCanvasSurfaceFrame({
    super.key,
    required this.layout,
    required this.zoom,
    required this.isCompact,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      key: frameKey,
      decoration: _surfaceDecoration(colorScheme),
      child: Stack(
        children: [
          Positioned.fill(child: child),
          Positioned(
            top: isCompact ? 6 : 10,
            right: isCompact ? 6 : 10,
            child: IgnorePointer(
              child: _CanvasLayoutBadge(layout: layout, zoom: zoom),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _surfaceDecoration(ColorScheme colorScheme) {
    final isPrint = layout == PageLayout.print;

    return BoxDecoration(
      color: colorScheme.surface,
      border: Border.all(
        color: colorScheme.outlineVariant.withValues(
          alpha: isPrint ? 0.72 : 0.42,
        ),
      ),
      borderRadius: BorderRadius.circular(isPrint ? 6 : 8),
      boxShadow: isPrint
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ]
          : const [],
    );
  }
}

class _CanvasLayoutBadge extends StatelessWidget {
  final PageLayout layout;
  final double zoom;

  const _CanvasLayoutBadge({required this.layout, required this.zoom});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final zoomPercent = (zoom.clamp(0.5, 1.5) * 100).round();

    return DecoratedBox(
      key: DocumentCanvasSurfaceFrame.layoutBadgeKey,
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.92),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.74),
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_iconForLayout(layout), size: 14, color: colorScheme.primary),
            const SizedBox(width: 5),
            Text(
              '${_labelForLayout(layout)} · $zoomPercent%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForLayout(PageLayout layout) {
    return switch (layout) {
      PageLayout.print => Icons.description_outlined,
      PageLayout.web => Icons.web_asset_outlined,
      PageLayout.outline => Icons.account_tree_outlined,
    };
  }

  String _labelForLayout(PageLayout layout) {
    return switch (layout) {
      PageLayout.print => 'Print Layout',
      PageLayout.web => 'Web Layout',
      PageLayout.outline => 'Outline Layout',
    };
  }
}
