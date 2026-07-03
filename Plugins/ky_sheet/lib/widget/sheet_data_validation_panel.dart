import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/cell/cell_selection.dart';
import '../model/cell/cell_validation.dart';
import '../state/spreadsheet_provider.dart';
import '../state/toolbar_provider.dart';
import '../theme/ky_sheet_theme.dart';

class SheetDataValidationPanel extends ConsumerStatefulWidget {
  const SheetDataValidationPanel({super.key});

  @override
  ConsumerState<SheetDataValidationPanel> createState() =>
      _SheetDataValidationPanelState();
}

class _SheetDataValidationPanelState
    extends ConsumerState<SheetDataValidationPanel> {
  final _minController = TextEditingController();
  final _maxController = TextEditingController();
  final _optionsController = TextEditingController();
  final _patternController = TextEditingController();
  final _errorController = TextEditingController();
  ValidationType _type = ValidationType.required;
  String? _syncedSelectionLabel;

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    _optionsController.dispose();
    _patternController.dispose();
    _errorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selection = ref.watch(selectedCellProvider);
    final data = ref.watch(spreadsheetProvider);
    final validation = selection == null
        ? null
        : data[selection.start]?.validation;
    _syncFromSelection(selection, validation);

    return Container(
      width: 286,
      decoration: const BoxDecoration(
        color: KySheetColors.surface,
        border: Border(left: BorderSide(color: KySheetColors.gridLine)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(
            selectionLabel: selection?.label ?? 'None',
            validationLabel: validation?.toString() ?? 'No validation',
          ),
          const Divider(height: 1, color: KySheetColors.gridLine),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                DropdownButtonFormField<ValidationType>(
                  key: ValueKey(_type),
                  initialValue: _type,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Rule Type',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final type in _availableTypes)
                      DropdownMenuItem(value: type, child: Text(_label(type))),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _type = value);
                  },
                ),
                if (_showsMinMax) ...[
                  const SizedBox(height: 10),
                  TextField(
                    key: const ValueKey('ky-sheet-validation-min'),
                    controller: _minController,
                    keyboardType: _numericKeyboard,
                    decoration: InputDecoration(
                      labelText: _minLabel,
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    key: const ValueKey('ky-sheet-validation-max'),
                    controller: _maxController,
                    keyboardType: _numericKeyboard,
                    decoration: InputDecoration(
                      labelText: _maxLabel,
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
                if (_type == ValidationType.list) ...[
                  const SizedBox(height: 10),
                  TextField(
                    key: const ValueKey('ky-sheet-validation-options'),
                    controller: _optionsController,
                    decoration: const InputDecoration(
                      labelText: 'Allowed Values',
                      hintText: 'Open, Pending, Closed',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                if (_type == ValidationType.regex) ...[
                  const SizedBox(height: 10),
                  TextField(
                    key: const ValueKey('ky-sheet-validation-pattern'),
                    controller: _patternController,
                    decoration: const InputDecoration(
                      labelText: 'Pattern',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                TextField(
                  key: const ValueKey('ky-sheet-validation-error-message'),
                  controller: _errorController,
                  decoration: const InputDecoration(
                    labelText: 'Error Message',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  key: const ValueKey('ky-sheet-validation-apply'),
                  onPressed: selection == null ? null : () => _apply(selection),
                  icon: const Icon(Icons.rule, size: 18),
                  label: const Text('Apply Validation'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  key: const ValueKey('ky-sheet-validation-clear'),
                  onPressed: selection == null
                      ? null
                      : () => ref
                            .read(toolbarControllerProvider)
                            .clearValidation(selection),
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('Clear Validation'),
                ),
                const SizedBox(height: 18),
                _SelectionValidationSummary(selection: selection),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool get _showsMinMax =>
      _type == ValidationType.number ||
      _type == ValidationType.date ||
      _type == ValidationType.minLength ||
      _type == ValidationType.maxLength ||
      _type == ValidationType.min ||
      _type == ValidationType.max;

  TextInputType? get _numericKeyboard =>
      _type == ValidationType.number ||
          _type == ValidationType.minLength ||
          _type == ValidationType.maxLength
      ? TextInputType.number
      : null;

  String get _minLabel {
    return switch (_type) {
      ValidationType.minLength => 'Minimum Length',
      ValidationType.maxLength => 'Minimum Length',
      ValidationType.date => 'Start Date',
      _ => 'Minimum',
    };
  }

  String get _maxLabel {
    return switch (_type) {
      ValidationType.minLength => 'Maximum Length',
      ValidationType.maxLength => 'Maximum Length',
      ValidationType.date => 'End Date',
      _ => 'Maximum',
    };
  }

  void _syncFromSelection(
    CellSelection? selection,
    CellValidation? validation,
  ) {
    if (selection == null || _syncedSelectionLabel == selection.label) return;
    _syncedSelectionLabel = selection.label;
    final nextValidation = validation;
    _type = nextValidation?.type == ValidationType.none
        ? ValidationType.required
        : nextValidation?.type ?? ValidationType.required;
    _minController.text = nextValidation?.min ?? '';
    _maxController.text = nextValidation?.max ?? '';
    _optionsController.text = nextValidation?.options?.join(', ') ?? '';
    _patternController.text = nextValidation?.pattern ?? '';
    _errorController.text = nextValidation?.errorMessage ?? '';
  }

  void _apply(CellSelection selection) {
    final validation = CellValidation(
      type: _type,
      min: _clean(_minController.text),
      max: _clean(_maxController.text),
      options: _type == ValidationType.list ? _parseOptions() : null,
      pattern: _type == ValidationType.regex
          ? _clean(_patternController.text)
          : null,
      errorMessage: _clean(_errorController.text),
    );
    ref.read(toolbarControllerProvider).applyValidation(selection, validation);
  }

  List<String> _parseOptions() {
    return _optionsController.text
        .split(',')
        .map((option) => option.trim())
        .where((option) => option.isNotEmpty)
        .toList();
  }

  static String? _clean(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String _label(ValidationType type) {
    return switch (type) {
      ValidationType.required => 'Required',
      ValidationType.number => 'Number',
      ValidationType.date => 'Date',
      ValidationType.list => 'Dropdown List',
      ValidationType.email => 'Email',
      ValidationType.url => 'URL',
      ValidationType.phone => 'Phone',
      ValidationType.regex => 'Pattern',
      ValidationType.minLength => 'Minimum Length',
      ValidationType.maxLength => 'Maximum Length',
      ValidationType.min => 'Minimum Value',
      ValidationType.max => 'Maximum Value',
      ValidationType.none || ValidationType.custom => type.name,
    };
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.selectionLabel,
    required this.validationLabel,
  });

  final String selectionLabel;
  final String validationLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Row(
        children: [
          const Icon(Icons.rule, color: KySheetColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Data Validation',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                Text(
                  validationLabel,
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
            selectionLabel,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: KySheetColors.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionValidationSummary extends ConsumerWidget {
  const _SelectionValidationSummary({required this.selection});

  final CellSelection? selection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCells = selection?.getCells() ?? const [];
    final data = ref.watch(spreadsheetProvider);
    var validated = 0;
    var invalid = 0;

    for (final address in selectedCells) {
      final cellData = data[address];
      final validation = cellData?.validation;
      if (validation == null || validation.type == ValidationType.none) {
        continue;
      }
      validated++;
      if (!validation.validate(cellData?.value ?? '')) invalid++;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KySheetColors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: KySheetColors.gridLine),
      ),
      child: Row(
        children: [
          Icon(
            invalid == 0 ? Icons.verified_outlined : Icons.error_outline,
            color: invalid == 0
                ? KySheetColors.accent
                : KySheetColors.validationError,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              selection == null
                  ? 'No active selection'
                  : '$validated validated, $invalid invalid',
              style: const TextStyle(
                color: KySheetColors.text,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _availableTypes = [
  ValidationType.required,
  ValidationType.number,
  ValidationType.date,
  ValidationType.list,
  ValidationType.email,
  ValidationType.url,
  ValidationType.phone,
  ValidationType.regex,
  ValidationType.minLength,
  ValidationType.maxLength,
  ValidationType.min,
  ValidationType.max,
];
