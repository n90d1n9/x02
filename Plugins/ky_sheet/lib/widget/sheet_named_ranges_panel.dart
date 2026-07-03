import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/cell/cell_selection.dart';
import '../model/sheet_named_range.dart';
import '../state/sheet_named_range_provider.dart';
import '../state/sheet_navigation_provider.dart';
import '../state/spreadsheet_provider.dart';
import '../theme/ky_sheet_theme.dart';
import 'sheet_sidebar_panel_surface.dart';

/// Sidebar panel for creating, updating, and navigating named cell ranges.
class SheetNamedRangesPanel extends ConsumerStatefulWidget {
  const SheetNamedRangesPanel({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  ConsumerState<SheetNamedRangesPanel> createState() =>
      _SheetNamedRangesPanelState();
}

/// State holder for named range form input and selection synchronization.
class _SheetNamedRangesPanelState extends ConsumerState<SheetNamedRangesPanel> {
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode(debugLabel: 'KySheetNamedRangeName');
  String? _syncedSelectionLabel;
  bool _hasNameError = false;

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selection = ref.watch(selectedCellProvider);
    final ranges = ref.watch(sheetNamedRangesProvider);
    _syncNameSuggestion(selection);

    return SheetSidebarPanelSurface(
      icon: Icons.bookmarks_outlined,
      title: 'Named Ranges',
      subtitle: 'Reusable ranges',
      trailing: SheetSidebarPanelLabelBadge(label: selection?.label ?? 'None'),
      onClose: widget.onClose,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _CreateNamedRangeForm(
            controller: _nameController,
            focusNode: _nameFocusNode,
            hasError: _hasNameError,
            selection: selection,
            onNameChanged: () {
              if (_hasNameError) {
                setState(() => _hasNameError = false);
              }
            },
            onSave: selection == null ? null : () => _save(selection),
          ),
          const SizedBox(height: 14),
          _RangeSummary(count: ranges.length),
          const SizedBox(height: 10),
          if (ranges.isEmpty)
            const _EmptyNamedRanges()
          else
            for (final range in ranges) ...[
              _NamedRangeTile(
                range: range,
                onGoTo: () => ref
                    .read(sheetNavigationControllerProvider)
                    .goTo(range.selection),
                onDelete: () => ref
                    .read(sheetNamedRangesProvider.notifier)
                    .remove(range.id),
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }

  void _syncNameSuggestion(CellSelection? selection) {
    if (selection == null || _nameFocusNode.hasFocus) return;
    if (_syncedSelectionLabel == selection.label) return;

    _syncedSelectionLabel = selection.label;
    if (_nameController.text.trim().isNotEmpty) return;

    final suggested = selection.isRange()
        ? 'Range_${selection.label.replaceAll(':', '_')}'
        : 'Cell_${selection.label}';
    _nameController.text = suggested;
    _nameController.selection = TextSelection.collapsed(
      offset: _nameController.text.length,
    );
  }

  void _save(CellSelection selection) {
    if (!SheetNamedRange.isValidName(_nameController.text)) {
      setState(() => _hasNameError = true);
      return;
    }

    final saved = ref
        .read(sheetNamedRangesProvider.notifier)
        .save(name: _nameController.text, selection: selection);
    setState(() {
      _hasNameError = false;
      _nameController.text = saved.name;
      _nameController.selection = TextSelection.collapsed(
        offset: saved.name.length,
      );
    });
    _nameFocusNode.unfocus();
  }
}

/// Form for creating or updating a named range from the current selection.
class _CreateNamedRangeForm extends StatelessWidget {
  const _CreateNamedRangeForm({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.selection,
    required this.onNameChanged,
    required this.onSave,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final CellSelection? selection;
  final VoidCallback onNameChanged;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KySheetColors.surfaceMuted,
        border: Border.all(color: KySheetColors.gridLine),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Current Selection',
                    style: TextStyle(
                      color: KySheetColors.mutedText,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    selection?.label ?? 'None',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('ky-sheet-named-range-name'),
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: 'Name',
                isDense: true,
                border: const OutlineInputBorder(),
                errorText: hasError ? 'Use a formula-safe name' : null,
              ),
              onChanged: (_) => onNameChanged(),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSave?.call(),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              key: const ValueKey('ky-sheet-named-range-save'),
              onPressed: onSave,
              icon: const Icon(Icons.bookmark_add_outlined, size: 18),
              label: const Text('Create / Update'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Summary row for the saved named range count.
class _RangeSummary extends StatelessWidget {
  const _RangeSummary({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Saved Names',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: KySheetColors.accentSoft,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: KySheetColors.headerActive),
          ),
          child: Text(
            count.toString(),
            style: const TextStyle(
              color: KySheetColors.accent,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

/// Saved named range row with navigation and delete actions.
class _NamedRangeTile extends StatelessWidget {
  const _NamedRangeTile({
    required this.range,
    required this.onGoTo,
    required this.onDelete,
  });

  final SheetNamedRange range;
  final VoidCallback onGoTo;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KySheetColors.surface,
        border: Border.all(color: KySheetColors.gridLine),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
        child: Row(
          children: [
            const Icon(
              Icons.bookmark_border,
              size: 18,
              color: KySheetColors.accent,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    range.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    range.selection.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: KySheetColors.mutedText,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              key: ValueKey('ky-sheet-named-range-go-${range.id}'),
              onPressed: onGoTo,
              tooltip: 'Go to ${range.name}',
              icon: const Icon(Icons.open_in_new, size: 17),
              style: IconButton.styleFrom(
                minimumSize: const Size.square(32),
                padding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              key: ValueKey('ky-sheet-named-range-delete-${range.id}'),
              onPressed: onDelete,
              tooltip: 'Delete ${range.name}',
              icon: const Icon(Icons.delete_outline, size: 18),
              color: KySheetColors.validationError,
              style: IconButton.styleFrom(
                minimumSize: const Size.square(32),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state for workbooks without saved named ranges.
class _EmptyNamedRanges extends StatelessWidget {
  const _EmptyNamedRanges();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KySheetColors.surfaceMuted,
        border: Border.all(color: KySheetColors.gridLine),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Column(
          children: [
            Icon(
              Icons.bookmarks_outlined,
              color: KySheetColors.mutedText,
              size: 24,
            ),
            SizedBox(height: 8),
            Text(
              'No named ranges yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: KySheetColors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
