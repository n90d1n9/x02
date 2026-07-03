import 'package:flutter/material.dart';

import '../../models/page_settings.dart';
import '../page_navigation/document_page_navigation_model.dart';
import 'document_status_chip.dart';
import 'document_status_popover.dart';

/// Displays the current page and opens a compact page-position summary.
class DocumentPageStatusChip extends StatelessWidget {
  static const chipKey = ValueKey('document-page-status-chip');
  static const menuKey = ValueKey('document-page-status-menu');
  static const openNavigatorKey = ValueKey(
    'document-page-status-open-navigator',
  );

  final int currentPage;
  final int totalPages;
  final PageSettings pageSettings;
  final VoidCallback? onOpenPageNavigator;

  const DocumentPageStatusChip({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.pageSettings,
    this.onOpenPageNavigator,
  });

  @override
  Widget build(BuildContext context) {
    final model = DocumentPageNavigationModel(
      currentPage: currentPage,
      totalPages: totalPages,
      pageSettings: pageSettings,
    );

    return PopupMenuButton<void>(
      tooltip: 'Show page details',
      itemBuilder: (context) => [
        PopupMenuItem<void>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: _DocumentPageStatusMenu(
            model: model,
            onOpenPageNavigator: onOpenPageNavigator,
          ),
        ),
      ],
      child: DocumentStatusChip(
        key: chipKey,
        icon: Icons.description_outlined,
        label: model.selectedPageLabel,
        tooltip: 'Current document page',
      ),
    );
  }
}

/// Renders page-position details and navigator access from the status bar.
class _DocumentPageStatusMenu extends StatelessWidget {
  final DocumentPageNavigationModel model;
  final VoidCallback? onOpenPageNavigator;

  const _DocumentPageStatusMenu({
    required this.model,
    required this.onOpenPageNavigator,
  });

  @override
  Widget build(BuildContext context) {
    return DocumentStatusPopover(
      contentKey: DocumentPageStatusChip.menuKey,
      icon: Icons.description_outlined,
      title: 'Page position',
      subtitle: model.formatLabel,
      width: 276,
      children: [
        DocumentStatusPopoverMetricLine(
          icon: Icons.my_location_outlined,
          label: 'Current page',
          value: 'Page ${model.selectedPage}',
        ),
        DocumentStatusPopoverMetricLine(
          icon: Icons.layers_outlined,
          label: 'Total pages',
          value: model.countLabel,
        ),
        DocumentStatusPopoverMetricLine(
          icon: Icons.timeline_outlined,
          label: 'Position',
          value: _progressLabel,
        ),
        if (model.pageCount > 1)
          DocumentStatusPopoverMetricLine(
            icon: Icons.unfold_more_outlined,
            label: 'Range',
            value: model.jumpRangeLabel,
          ),
        if (onOpenPageNavigator != null)
          DocumentStatusPopoverActionButton(
            actionKey: DocumentPageStatusChip.openNavigatorKey,
            icon: Icons.view_sidebar_outlined,
            label: 'Open navigator',
            onPressed: () => _openNavigator(context),
          ),
      ],
    );
  }

  String get _progressLabel {
    final progress = (model.selectedPage / model.pageCount * 100).round().clamp(
      1,
      100,
    );
    return '$progress% through';
  }

  void _openNavigator(BuildContext context) {
    Navigator.of(context).pop();
    onOpenPageNavigator?.call();
  }
}
