import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/page_layout.dart';
import '../models/page_settings.dart';
import 'document_canvas_surface_frame.dart';
import 'document_page_chrome.dart';
import 'document_page_ruler.dart';
import 'document_page_vertical_ruler.dart';
import 'page_margin/document_page_margin_guides.dart';
import 'ruler/document_ruler_corner_button.dart';
import 'ruler/document_ruler_metrics_chip.dart';

/// Provides the document editing canvas across print, web, and outline layouts.
class DocumentEditorCanvas extends StatelessWidget {
  static const surfaceKey = ValueKey('document-editor-canvas-surface');

  final PageLayout layout;
  final PageSettings pageSettings;
  final int currentPage;
  final double zoom;
  final ValueChanged<PageSettings>? onPageSettingsChanged;
  final VoidCallback? onPageSettingsPressed;
  final Widget child;

  const DocumentEditorCanvas({
    super.key,
    required this.layout,
    this.pageSettings = const PageSettings(),
    this.currentPage = 1,
    this.zoom = 1.0,
    this.onPageSettingsChanged,
    this.onPageSettingsPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: _backgroundColor(colorScheme),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 700;
          final outerPadding = EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 28,
            vertical: isCompact ? 12 : 24,
          );
          final availableWidth = math.max(
            0.0,
            constraints.maxWidth - outerPadding.horizontal,
          );
          final availableHeight = math.max(
            0.0,
            constraints.maxHeight - outerPadding.vertical,
          );
          final effectiveZoom = zoom.clamp(0.5, 1.5).toDouble();
          final surfaceWidth = math.min(
            _maxSurfaceWidth * effectiveZoom,
            availableWidth,
          );

          return Padding(
            padding: outerPadding,
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                key: surfaceKey,
                width: surfaceWidth,
                height: availableHeight,
                child: DocumentCanvasSurfaceFrame(
                  layout: layout,
                  zoom: effectiveZoom,
                  isCompact: isCompact,
                  child: Padding(
                    padding: _innerPadding(isCompact),
                    child: _CanvasContent(
                      layout: layout,
                      pageSettings: pageSettings,
                      currentPage: currentPage,
                      onPageSettingsChanged: onPageSettingsChanged,
                      onPageSettingsPressed: onPageSettingsPressed,
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  double get _maxSurfaceWidth {
    return switch (layout) {
      PageLayout.print => 816,
      PageLayout.web => 1080,
      PageLayout.outline => 960,
    };
  }

  Color _backgroundColor(ColorScheme colorScheme) {
    return switch (layout) {
      PageLayout.print => colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.38,
      ),
      PageLayout.web => colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.18,
      ),
      PageLayout.outline => colorScheme.surface,
    };
  }

  EdgeInsets _innerPadding(bool isCompact) {
    return switch (layout) {
      PageLayout.print => EdgeInsets.symmetric(
        horizontal: isCompact ? 14 : 34,
        vertical: isCompact ? 12 : 28,
      ),
      PageLayout.web => EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 22,
        vertical: isCompact ? 10 : 18,
      ),
      PageLayout.outline => EdgeInsets.all(isCompact ? 10 : 16),
    };
  }
}

/// Composes print-specific canvas aids while keeping web and outline layouts bare.
class _CanvasContent extends StatelessWidget {
  static const _verticalRulerWidth = 28.0;
  static const _rulerGap = 12.0;

  final PageLayout layout;
  final PageSettings pageSettings;
  final int currentPage;
  final ValueChanged<PageSettings>? onPageSettingsChanged;
  final VoidCallback? onPageSettingsPressed;
  final Widget child;

  const _CanvasContent({
    required this.layout,
    required this.pageSettings,
    required this.currentPage,
    required this.onPageSettingsChanged,
    required this.onPageSettingsPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (layout != PageLayout.print) return child;

    return LayoutBuilder(
      builder: (context, constraints) {
        final showVerticalRuler =
            constraints.maxWidth >= 520 && constraints.maxHeight >= 280;
        final showMetricsChip = constraints.maxWidth >= 720;

        return Column(
          children: [
            Row(
              children: [
                if (showVerticalRuler) ...[
                  SizedBox(
                    width: _verticalRulerWidth,
                    height: 28,
                    child: DocumentRulerCornerButton(
                      pageSettings: pageSettings,
                      onPageSettingsChanged: onPageSettingsChanged,
                      onPressed: onPageSettingsPressed,
                    ),
                  ),
                  const SizedBox(width: _rulerGap),
                ],
                Expanded(
                  child: DocumentPageRuler(
                    pageSettings: pageSettings,
                    onMarginsChanged: _onMarginsChanged,
                  ),
                ),
                if (showMetricsChip) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 204,
                    height: 28,
                    child: DocumentRulerMetricsChip(
                      pageSettings: pageSettings,
                      onMarginsChanged: _onMarginsChanged,
                      onPressed: onPageSettingsPressed,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showVerticalRuler) ...[
                    SizedBox(
                      width: _verticalRulerWidth,
                      child: DocumentPageVerticalRuler(
                        pageSettings: pageSettings,
                        onMarginsChanged: _onMarginsChanged,
                      ),
                    ),
                    const SizedBox(width: _rulerGap),
                  ],
                  Expanded(
                    child: DocumentPageMarginGuides(
                      pageSettings: pageSettings,
                      child: DocumentPageChrome(
                        pageSettings: pageSettings,
                        currentPage: currentPage,
                        onPageSettingsChanged: onPageSettingsChanged,
                        child: child,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _onMarginsChanged(EdgeInsets margins) {
    onPageSettingsChanged?.call(pageSettings.copyWith(margins: margins));
  }
}
