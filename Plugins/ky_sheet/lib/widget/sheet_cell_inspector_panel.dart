import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/cell/cell_address.dart';
import '../model/cell/cell_data.dart';
import '../state/spreadsheet_provider.dart';
import '../theme/ky_sheet_theme.dart';
import '../utils/sheet_formula_error_status.dart';
import '../utils/sheet_validation_status.dart';

class SheetCellInspectorPanel extends ConsumerStatefulWidget {
  const SheetCellInspectorPanel({super.key});

  @override
  ConsumerState<SheetCellInspectorPanel> createState() =>
      _SheetCellInspectorPanelState();
}

class _SheetCellInspectorPanelState
    extends ConsumerState<SheetCellInspectorPanel> {
  final _valueController = TextEditingController();
  final _formulaController = TextEditingController();
  final _commentController = TextEditingController();
  final _hyperlinkController = TextEditingController();
  final _focusNodes = <FocusNode>[
    FocusNode(debugLabel: 'KySheetInspectorValue'),
    FocusNode(debugLabel: 'KySheetInspectorFormula'),
    FocusNode(debugLabel: 'KySheetInspectorComment'),
    FocusNode(debugLabel: 'KySheetInspectorHyperlink'),
  ];
  CellAddress? _syncedAddress;

  FocusNode get _valueFocusNode => _focusNodes[0];
  FocusNode get _formulaFocusNode => _focusNodes[1];
  FocusNode get _commentFocusNode => _focusNodes[2];
  FocusNode get _hyperlinkFocusNode => _focusNodes[3];

  @override
  void dispose() {
    _valueController.dispose();
    _formulaController.dispose();
    _commentController.dispose();
    _hyperlinkController.dispose();
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selection = ref.watch(selectedCellProvider);
    final data = ref.watch(spreadsheetProvider);
    final address = selection?.start;
    final cellData = address == null ? null : data[address] ?? CellData();
    _syncControllers(address, cellData);

    return Container(
      width: 312,
      decoration: const BoxDecoration(
        color: KySheetColors.surface,
        border: Border(left: BorderSide(color: KySheetColors.gridLine)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(
            addressLabel: address?.label ?? 'None',
            selectionLabel: selection?.label ?? 'No selection',
          ),
          const Divider(height: 1, color: KySheetColors.gridLine),
          Expanded(
            child: address == null || cellData == null
                ? const _EmptyInspector()
                : ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      _Section(
                        icon: Icons.edit_note,
                        title: 'Content',
                        child: Column(
                          children: [
                            TextField(
                              key: const ValueKey('ky-sheet-inspector-value'),
                              controller: _valueController,
                              focusNode: _valueFocusNode,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Value',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              key: const ValueKey('ky-sheet-inspector-formula'),
                              controller: _formulaController,
                              focusNode: _formulaFocusNode,
                              decoration: const InputDecoration(
                                labelText: 'Formula',
                                hintText: '=SUM(A1:A10)',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    key: const ValueKey(
                                      'ky-sheet-inspector-save-content',
                                    ),
                                    onPressed: () => _saveContent(address),
                                    icon: const Icon(Icons.save, size: 18),
                                    label: const Text('Save'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton.filledTonal(
                                  key: const ValueKey(
                                    'ky-sheet-inspector-clear-cell',
                                  ),
                                  onPressed: () => ref
                                      .read(spreadsheetProvider.notifier)
                                      .clearCell(address),
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: 'Clear Cell',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _Section(
                        icon: Icons.badge_outlined,
                        title: 'Metadata',
                        child: Column(
                          children: [
                            TextField(
                              key: const ValueKey('ky-sheet-inspector-comment'),
                              controller: _commentController,
                              focusNode: _commentFocusNode,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Comment',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              key: const ValueKey(
                                'ky-sheet-inspector-hyperlink',
                              ),
                              controller: _hyperlinkController,
                              focusNode: _hyperlinkFocusNode,
                              decoration: const InputDecoration(
                                labelText: 'Hyperlink',
                                hintText: 'https://example.com',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    key: const ValueKey(
                                      'ky-sheet-inspector-save-metadata',
                                    ),
                                    onPressed: () =>
                                        _saveMetadata(address, cellData),
                                    icon: const Icon(
                                      Icons.bookmark_add_outlined,
                                    ),
                                    label: const Text('Save Metadata'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton.filledTonal(
                                  key: const ValueKey(
                                    'ky-sheet-inspector-clear-metadata',
                                  ),
                                  onPressed: () =>
                                      _clearMetadata(address, cellData),
                                  icon: const Icon(Icons.backspace_outlined),
                                  tooltip: 'Clear Metadata',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DetailsSection(cellData: cellData),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _syncControllers(CellAddress? address, CellData? cellData) {
    if (address != _syncedAddress) {
      _syncedAddress = address;
      _setControllerText(_valueController, cellData?.value ?? '');
      _setControllerText(_formulaController, cellData?.formula ?? '');
      _setControllerText(_commentController, cellData?.comment ?? '');
      _setControllerText(_hyperlinkController, cellData?.hyperlink ?? '');
      return;
    }

    if (!_valueFocusNode.hasFocus) {
      _setControllerText(_valueController, cellData?.value ?? '');
    }
    if (!_formulaFocusNode.hasFocus) {
      _setControllerText(_formulaController, cellData?.formula ?? '');
    }
    if (!_commentFocusNode.hasFocus) {
      _setControllerText(_commentController, cellData?.comment ?? '');
    }
    if (!_hyperlinkFocusNode.hasFocus) {
      _setControllerText(_hyperlinkController, cellData?.hyperlink ?? '');
    }
  }

  void _setControllerText(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.text = value;
    controller.selection = TextSelection.collapsed(offset: value.length);
  }

  void _saveContent(CellAddress address) {
    final formula = _formulaController.text.trim();
    if (formula.isNotEmpty) {
      ref
          .read(spreadsheetProvider.notifier)
          .updateCellValue(
            address,
            formula.startsWith('=') ? formula : '=$formula',
          );
      return;
    }

    ref
        .read(spreadsheetProvider.notifier)
        .updateCellValue(address, _valueController.text);
  }

  void _saveMetadata(CellAddress address, CellData cellData) {
    final comment = _commentController.text.trim();
    final hyperlink = _hyperlinkController.text.trim();
    ref
        .read(spreadsheetProvider.notifier)
        .updateCell(
          address,
          cellData.copyWith(
            comment: comment.isEmpty ? null : comment,
            hyperlink: hyperlink.isEmpty ? null : hyperlink,
            clearComment: comment.isEmpty,
            clearHyperlink: hyperlink.isEmpty,
          ),
        );
  }

  void _clearMetadata(CellAddress address, CellData cellData) {
    ref
        .read(spreadsheetProvider.notifier)
        .updateCell(
          address,
          cellData.copyWith(clearComment: true, clearHyperlink: true),
        );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.addressLabel,
    required this.selectionLabel,
  });

  final String addressLabel;
  final String selectionLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: KySheetColors.accent, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cell Inspector',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                Text(
                  selectionLabel,
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
          Text(
            addressLabel,
            style: const TextStyle(
              color: KySheetColors.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({required this.cellData});

  final CellData cellData;

  @override
  Widget build(BuildContext context) {
    final validationStatus = SheetValidationStatus.fromCell(cellData);
    final formulaErrorStatus = SheetFormulaErrorStatus.fromCell(cellData);
    final style = cellData.style;

    return _Section(
      icon: Icons.tune,
      title: 'Details',
      child: Column(
        children: [
          if (formulaErrorStatus.hasError) ...[
            _FormulaErrorBanner(status: formulaErrorStatus),
            const SizedBox(height: 10),
          ],
          _InfoRow(
            label: 'Validation',
            value: validationStatus.hasValidation
                ? validationStatus.description
                : 'None',
          ),
          _InfoRow(
            label: 'Number Format',
            value: style.numberFormat ?? 'Automatic',
          ),
          _InfoRow(label: 'Align', value: style.align.name),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (style.bold) const _StyleChip(label: 'Bold'),
              if (style.italic) const _StyleChip(label: 'Italic'),
              if (style.underline) const _StyleChip(label: 'Underline'),
              if (style.wrapText) const _StyleChip(label: 'Wrap'),
              if (style.backgroundColor != null)
                const _StyleChip(label: 'Fill'),
              if (style.borderTop ||
                  style.borderRight ||
                  style.borderBottom ||
                  style.borderLeft)
                const _StyleChip(label: 'Borders'),
              if (!style.bold &&
                  !style.italic &&
                  !style.underline &&
                  !style.wrapText &&
                  style.backgroundColor == null &&
                  !style.borderTop &&
                  !style.borderRight &&
                  !style.borderBottom &&
                  !style.borderLeft)
                const _StyleChip(label: 'Default style'),
            ],
          ),
        ],
      ),
    );
  }
}

class _FormulaErrorBanner extends StatelessWidget {
  const _FormulaErrorBanner({required this.status});

  final SheetFormulaErrorStatus status;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KySheetColors.validationSoft,
        border: Border.all(color: KySheetColors.validationError),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline,
              color: KySheetColors.validationError,
              size: 17,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${status.title} ${status.code}',
                    style: const TextStyle(
                      color: KySheetColors.validationError,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    status.message,
                    style: const TextStyle(
                      color: KySheetColors.text,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    status.suggestion,
                    style: const TextStyle(
                      color: KySheetColors.mutedText,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KySheetColors.surface,
        border: Border.all(color: KySheetColors.gridLine),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: KySheetColors.mutedText, size: 17),
                const SizedBox(width: 7),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: KySheetColors.mutedText,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _StyleChip extends StatelessWidget {
  const _StyleChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KySheetColors.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: KySheetColors.gridLine),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: const TextStyle(
            color: KySheetColors.text,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _EmptyInspector extends StatelessWidget {
  const _EmptyInspector();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, color: KySheetColors.mutedText, size: 28),
            SizedBox(height: 10),
            Text(
              'Select a cell to inspect its content and metadata',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: KySheetColors.mutedText,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
