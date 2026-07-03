import 'package:flutter/material.dart';

import '../models/document_editing_mode.dart';
import '../models/document_state.dart';
import '../models/page_layout.dart';
import '../services/document_statistics.dart';
import 'document_import_status_chip.dart';
import 'document_layout_switcher.dart';
import 'document_writing_insights_dialog.dart';
import 'document_writing_quality_badge.dart';
import 'document_zoom_controls.dart';
import 'review_mode/document_editing_mode_status_chip.dart';
import 'status_bar/document_page_status_chip.dart';
import 'status_bar/document_selection_status_chip.dart';
import 'status_bar/document_statistics_status_chip.dart';
import 'status_bar/document_status_chip.dart';
import 'status_bar/document_text_style_status_chip.dart';

/// Shows live document metadata and view controls at the bottom of the editor.
class DocumentStatusBar extends StatelessWidget {
  final DocumentState documentState;
  final DocumentStatistics statistics;
  final double zoom;
  final VoidCallback? onZoomOut;
  final VoidCallback? onZoomIn;
  final VoidCallback? onResetZoom;
  final ValueChanged<double>? onZoomChanged;
  final ValueChanged<PageLayout>? onSetPageLayout;
  final VoidCallback? onOpenPageNavigator;
  final DocumentEditingMode editingMode;

  const DocumentStatusBar({
    super.key,
    required this.documentState,
    required this.statistics,
    this.zoom = 1.0,
    this.onZoomOut,
    this.onZoomIn,
    this.onResetZoom,
    this.onZoomChanged,
    this.onSetPageLayout,
    this.onOpenPageNavigator,
    this.editingMode = DocumentEditingMode.editing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final snapshot = statistics.snapshot;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
          top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return _StatusBarContent(
            documentState: documentState,
            statistics: snapshot,
            zoom: zoom,
            editingMode: editingMode,
            onZoomOut: onZoomOut,
            onZoomIn: onZoomIn,
            onResetZoom: onResetZoom,
            onZoomChanged: onZoomChanged,
            onSetPageLayout: onSetPageLayout,
            onOpenPageNavigator: onOpenPageNavigator,
            compact: constraints.maxWidth < 820,
            showEditingMode:
                constraints.maxWidth >= 1180 ||
                editingMode != DocumentEditingMode.editing,
            showStyleStatus: constraints.maxWidth >= 1240,
            showCharacterCount: constraints.maxWidth >= 1360,
            scrollable: constraints.maxWidth < 560,
          );
        },
      ),
    );
  }
}

class _StatusBarContent extends StatelessWidget {
  final DocumentState documentState;
  final DocumentTextStatistics statistics;
  final double zoom;
  final DocumentEditingMode editingMode;
  final VoidCallback? onZoomOut;
  final VoidCallback? onZoomIn;
  final VoidCallback? onResetZoom;
  final ValueChanged<double>? onZoomChanged;
  final ValueChanged<PageLayout>? onSetPageLayout;
  final VoidCallback? onOpenPageNavigator;
  final bool compact;
  final bool showEditingMode;
  final bool showStyleStatus;
  final bool showCharacterCount;
  final bool scrollable;

  const _StatusBarContent({
    required this.documentState,
    required this.statistics,
    required this.zoom,
    required this.editingMode,
    required this.onZoomOut,
    required this.onZoomIn,
    required this.onResetZoom,
    required this.onZoomChanged,
    required this.onSetPageLayout,
    required this.onOpenPageNavigator,
    required this.compact,
    required this.showEditingMode,
    required this.showStyleStatus,
    required this.showCharacterCount,
    required this.scrollable,
  });

  @override
  Widget build(BuildContext context) {
    final leftItems = _leftItems(context);
    final rightItems = _rightItems();

    if (scrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [...leftItems, const SizedBox(width: 24), ...rightItems],
        ),
      );
    }

    return Row(
      children: [
        Flexible(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(mainAxisSize: MainAxisSize.min, children: leftItems),
          ),
        ),
        const SizedBox(width: 12),
        ...rightItems,
      ],
    );
  }

  List<Widget> _leftItems(BuildContext context) {
    return [
      DocumentPageStatusChip(
        currentPage: documentState.currentPage,
        totalPages: documentState.totalPages,
        pageSettings: documentState.pageSettings,
        onOpenPageNavigator: onOpenPageNavigator,
      ),
      const SizedBox(width: 8),
      DocumentStatisticsStatusChip(statistics: statistics),
      if (showEditingMode) ...[
        const SizedBox(width: 8),
        DocumentEditingModeStatusChip(mode: editingMode),
      ],
      DocumentSelectionStatusChip(controller: documentState.controller),
      if (!compact) ...[
        if (showStyleStatus) ...[
          const SizedBox(width: 8),
          DocumentTextStyleStatusChip(controller: documentState.controller),
        ],
        const SizedBox(width: 8),
        DocumentStatusChip(
          icon: Icons.schedule_outlined,
          label: '${statistics.readingTimeLabel} read',
          tooltip: statistics.readingTimeTooltip,
        ),
        if (showCharacterCount) ...[
          const SizedBox(width: 8),
          DocumentStatusChip(
            icon: Icons.article,
            label: statistics.characterCountLabel,
            tooltip: statistics.characterCountTooltip,
          ),
        ],
        const DocumentStatusDivider(),
        DocumentWritingQualityBadge(
          insights: statistics.writingInsights,
          includePrefix: true,
          showScore: false,
          dense: true,
          onPressed: () => DocumentWritingInsightsDialog.show(
            context,
            insights: statistics.writingInsights,
          ),
        ),
      ],
      if (!documentState.importStatus.isIdle) ...[
        const DocumentStatusDivider(),
        DocumentImportStatusChip(status: documentState.importStatus),
      ],
    ];
  }

  List<Widget> _rightItems() {
    return [
      DocumentZoomControls(
        zoom: zoom,
        onZoomOut: onZoomOut,
        onZoomIn: onZoomIn,
        onResetZoom: onResetZoom,
        onZoomChanged: onZoomChanged,
        showSlider: !compact,
      ),
      const SizedBox(width: 10),
      DocumentLayoutSwitcher(
        currentLayout: documentState.currentLayout,
        onLayoutSelected: onSetPageLayout,
        showLabel: false,
      ),
      const SizedBox(width: 10),
      DocumentSaveStatusBadge(
        hasUnsavedChanges: documentState.hasUnsavedChanges,
      ),
    ];
  }
}
