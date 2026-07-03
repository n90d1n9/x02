import 'package:flutter/material.dart';

import '../model/cell/cell_selection.dart';
import '../model/sheet_table.dart';
import '../theme/ky_sheet_theme.dart';
import '../utils/sheet_table_style_resolver.dart';

/// Reusable design tile for editing one structured table's presentation.
class SheetTableDesignTile extends StatelessWidget {
  const SheetTableDesignTile({
    super.key,
    required this.table,
    required this.activeSelection,
    required this.expandedSelection,
    required this.onGoTo,
    required this.onNameSubmitted,
    required this.onUseSelection,
    required this.onExpandToData,
    required this.onStyleChanged,
    required this.onHeaderRowChanged,
    required this.onBandedRowsChanged,
    required this.onTotalsRowChanged,
    required this.onRemove,
  });

  final SheetTable table;
  final CellSelection? activeSelection;
  final CellSelection expandedSelection;
  final VoidCallback onGoTo;
  final ValueChanged<String> onNameSubmitted;
  final VoidCallback? onUseSelection;
  final ValueChanged<CellSelection> onExpandToData;
  final ValueChanged<SheetTableStyleId> onStyleChanged;
  final ValueChanged<bool> onHeaderRowChanged;
  final ValueChanged<bool> onBandedRowsChanged;
  final ValueChanged<bool> onTotalsRowChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final palette = SheetTableStyleResolver.paletteFor(table.styleId);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: KySheetColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: KySheetColors.gridLineStrong),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            offset: Offset(0, 8),
            blurRadius: 18,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TableTileHeader(
            table: table,
            palette: palette,
            onGoTo: onGoTo,
            onRemove: onRemove,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TableNameEditor(
                  tableId: table.id,
                  tableName: table.name,
                  onSubmitted: onNameSubmitted,
                ),
                const SizedBox(height: 10),
                _TableStylePicker(
                  tableId: table.id,
                  value: table.styleId,
                  onChanged: onStyleChanged,
                ),
                const SizedBox(height: 10),
                _TableRangeEditor(
                  table: table,
                  activeSelection: activeSelection,
                  expandedSelection: expandedSelection,
                  onUseSelection: onUseSelection,
                  onExpandToData: onExpandToData,
                ),
                const SizedBox(height: 8),
                _TableToggleRow(
                  key: ValueKey('ky-sheet-table-header-${table.id}'),
                  icon: Icons.title,
                  label: 'Header row',
                  value: table.showHeaderRow,
                  onChanged: onHeaderRowChanged,
                ),
                _TableToggleRow(
                  key: ValueKey('ky-sheet-table-banding-${table.id}'),
                  icon: Icons.view_stream_outlined,
                  label: 'Banded rows',
                  value: table.showBandedRows,
                  onChanged: onBandedRowsChanged,
                ),
                _TableToggleRow(
                  key: ValueKey('ky-sheet-table-totals-${table.id}'),
                  icon: Icons.functions,
                  label: 'Totals row',
                  value: table.showTotalsRow,
                  onChanged: onTotalsRowChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TableRangeEditor extends StatelessWidget {
  const _TableRangeEditor({
    required this.table,
    required this.activeSelection,
    required this.expandedSelection,
    required this.onUseSelection,
    required this.onExpandToData,
  });

  final SheetTable table;
  final CellSelection? activeSelection;
  final CellSelection expandedSelection;
  final VoidCallback? onUseSelection;
  final ValueChanged<CellSelection> onExpandToData;

  @override
  Widget build(BuildContext context) {
    final hasDifferentSelection =
        activeSelection != null &&
        activeSelection!.label != table.selection.label;
    final canExpand = expandedSelection.label != table.selection.label;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: KySheetColors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: KySheetColors.gridLine),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.open_in_full,
                  color: KySheetColors.mutedText,
                  size: 17,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Range',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  table.selection.label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: KySheetColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: ValueKey('ky-sheet-table-use-selection-${table.id}'),
                    onPressed: hasDifferentSelection ? onUseSelection : null,
                    icon: const Icon(Icons.select_all, size: 16),
                    label: const Text('Use Selection'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    key: ValueKey('ky-sheet-table-expand-data-${table.id}'),
                    onPressed: canExpand
                        ? () => onExpandToData(expandedSelection)
                        : null,
                    icon: const Icon(Icons.unfold_more, size: 16),
                    label: const Text('Expand'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TableTileHeader extends StatelessWidget {
  const _TableTileHeader({
    required this.table,
    required this.palette,
    required this.onGoTo,
    required this.onRemove,
  });

  final SheetTable table;
  final SheetTableStylePalette palette;
  final VoidCallback onGoTo;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: palette.headerBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  table.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  table.selection.label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xD9FFFFFF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Tooltip(
            message: 'Go to ${table.selection.label}',
            child: IconButton(
              key: ValueKey('ky-sheet-table-go-to-${table.id}'),
              onPressed: onGoTo,
              icon: const Icon(Icons.my_location, size: 18),
              color: Colors.white,
              visualDensity: VisualDensity.compact,
            ),
          ),
          Tooltip(
            message: 'Remove ${table.name}',
            child: IconButton(
              key: ValueKey('ky-sheet-table-remove-${table.id}'),
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline, size: 18),
              color: Colors.white,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}

class _TableNameEditor extends StatefulWidget {
  const _TableNameEditor({
    required this.tableId,
    required this.tableName,
    required this.onSubmitted,
  });

  final String tableId;
  final String tableName;
  final ValueChanged<String> onSubmitted;

  @override
  State<_TableNameEditor> createState() => _TableNameEditorState();
}

class _TableNameEditorState extends State<_TableNameEditor> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode(debugLabel: 'KySheetTableName');

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.tableName);
  }

  @override
  void didUpdateWidget(covariant _TableNameEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && widget.tableName != _controller.text) {
      _controller.text = widget.tableName;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: ValueKey('ky-sheet-table-name-${widget.tableId}'),
      controller: _controller,
      focusNode: _focusNode,
      decoration: const InputDecoration(
        labelText: 'Table name',
        isDense: true,
        border: OutlineInputBorder(),
      ),
      onSubmitted: _submit,
      textInputAction: TextInputAction.done,
    );
  }

  void _submit(String value) {
    widget.onSubmitted(value);
    _focusNode.unfocus();
  }
}

class _TableStylePicker extends StatelessWidget {
  const _TableStylePicker({
    required this.tableId,
    required this.value,
    required this.onChanged,
  });

  final String tableId;
  final SheetTableStyleId value;
  final ValueChanged<SheetTableStyleId> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<SheetTableStyleId>(
      key: ValueKey('ky-sheet-table-style-$tableId'),
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Style',
        isDense: true,
        border: OutlineInputBorder(),
      ),
      items: [
        for (final styleId in SheetTableStyleId.values)
          DropdownMenuItem(
            value: styleId,
            child: _StyleOption(styleId: styleId),
          ),
      ],
      onChanged: (styleId) {
        if (styleId == null) return;
        onChanged(styleId);
      },
    );
  }
}

class _StyleOption extends StatelessWidget {
  const _StyleOption({required this.styleId});

  final SheetTableStyleId styleId;

  @override
  Widget build(BuildContext context) {
    final palette = SheetTableStyleResolver.paletteFor(styleId);

    return Row(
      children: [
        _StyleSwatch(palette: palette),
        const SizedBox(width: 8),
        Text(styleId.label),
      ],
    );
  }
}

class _StyleSwatch extends StatelessWidget {
  const _StyleSwatch({required this.palette});

  final SheetTableStylePalette palette;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: SizedBox(
        width: 34,
        height: 18,
        child: Column(
          children: [
            Expanded(child: ColoredBox(color: palette.headerBackground)),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: ColoredBox(color: palette.bodyBackground)),
                  Expanded(child: ColoredBox(color: palette.bandBackground)),
                  Expanded(child: ColoredBox(color: palette.totalBackground)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableToggleRow extends StatelessWidget {
  const _TableToggleRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: value,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: SizedBox(
          height: 42,
          child: Row(
            children: [
              Icon(icon, color: KySheetColors.mutedText, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
