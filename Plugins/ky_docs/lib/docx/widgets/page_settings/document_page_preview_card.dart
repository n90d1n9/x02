import 'package:flutter/material.dart';

import '../../models/page_margin_preset.dart';
import '../../models/page_orientation.dart';
import '../../models/page_settings.dart';
import '../../models/page_size.dart';
import '../page_margin/document_page_margin_guide_geometry.dart';

/// Shows a compact page setup preview with size, margins, and chrome hints.
class DocumentPagePreviewCard extends StatelessWidget {
  static const previewKey = ValueKey('document-page-preview-card');
  static const pageSheetKey = ValueKey('document-page-preview-sheet');
  static const marginFrameKey = ValueKey('document-page-preview-margin-frame');

  final PageSettings settings;

  const DocumentPagePreviewCard({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pageSize = settings.getPageSize();

    return Container(
      key: previewKey,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          _PagePreviewThumbnail(settings: settings),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${settings.pageSize.label} ${settings.orientation.label.toLowerCase()}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '${pageSize.width.round()} x ${pageSize.height.round()} pt',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                _MarginSummary(settings: settings),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Draws a scaled page thumbnail with the active margin rectangle.
class _PagePreviewThumbnail extends StatelessWidget {
  static const _maxWidth = 58.0;
  static const _height = 76.0;

  final PageSettings settings;

  const _PagePreviewThumbnail({required this.settings});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pageSize = settings.getPageSize();
    final width = (_height * pageSize.width / pageSize.height).clamp(
      42.0,
      _maxWidth,
    );

    return SizedBox(
      width: _maxWidth,
      height: _height + 8,
      child: Center(
        child: SizedBox(
          key: DocumentPagePreviewCard.pageSheetKey,
          width: width,
          height: _height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: colorScheme.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final geometry = DocumentPageMarginGuideGeometry.fromSettings(
                  pageSettings: settings,
                  surfaceSize: Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  ),
                );
                final writingRect = geometry.writingRect;

                return Stack(
                  children: [
                    Positioned.fromRect(
                      rect: writingRect,
                      child: DecoratedBox(
                        key: DocumentPagePreviewCard.marginFrameKey,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(
                            alpha: 0.22,
                          ),
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.34),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: Column(
                            children: [
                              if (settings.showHeader)
                                const _PreviewLine(widthFactor: 0.8),
                              const Spacer(),
                              if (settings.showPageNumbers)
                                const _PreviewLine(widthFactor: 0.45),
                              if (settings.showFooter) ...[
                                const SizedBox(height: 3),
                                const _PreviewLine(widthFactor: 0.65),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Summarizes the active margin preset and exact point values.
class _MarginSummary extends StatelessWidget {
  final PageSettings settings;

  const _MarginSummary({required this.settings});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final preset = DocumentPageMarginPresetMatcher.match(settings.margins);
    final presetLabel = preset == null
        ? 'Custom margins'
        : '${preset.label} margins';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          presetLabel,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _exactMarginLabel(settings.margins),
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  String _exactMarginLabel(EdgeInsets margins) {
    return 'T ${margins.top.round()} · R ${margins.right.round()} · '
        'B ${margins.bottom.round()} · L ${margins.left.round()} pt';
  }
}

/// Draws one small line in the page preview content area.
class _PreviewLine extends StatelessWidget {
  final double widthFactor;

  const _PreviewLine({required this.widthFactor});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: 3,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.32),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
