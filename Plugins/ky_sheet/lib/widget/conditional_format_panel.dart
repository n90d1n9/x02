import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/conditional_format_rule.dart';
import '../state/spreadsheet_provider.dart';
import '../theme/ky_sheet_theme.dart';

class ConditionalFormatPanel extends ConsumerStatefulWidget {
  const ConditionalFormatPanel({super.key});

  @override
  ConsumerState<ConditionalFormatPanel> createState() =>
      _ConditionalFormatPanelState();
}

class _ConditionalFormatPanelState
    extends ConsumerState<ConditionalFormatPanel> {
  final _operandController = TextEditingController(text: '0');
  ConditionalFormatCondition _condition =
      ConditionalFormatCondition.greaterThan;
  _RulePreset _preset = _RulePreset.green;

  @override
  void dispose() {
    _operandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selection = ref.watch(selectedCellProvider);
    final rules = ref.watch(conditionalFormatRulesProvider);
    final operandEnabled = _condition != ConditionalFormatCondition.notEmpty;

    return Container(
      width: 286,
      decoration: const BoxDecoration(
        color: KySheetColors.surface,
        border: Border(left: BorderSide(color: KySheetColors.gridLine)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(selectionLabel: selection?.label ?? 'None'),
          const Divider(height: 1, color: KySheetColors.gridLine),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                DropdownButtonFormField<ConditionalFormatCondition>(
                  initialValue: _condition,
                  decoration: const InputDecoration(
                    labelText: 'Condition',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final condition in ConditionalFormatCondition.values)
                      DropdownMenuItem(
                        value: condition,
                        child: Text(_conditionLabel(condition)),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _condition = value);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _operandController,
                  enabled: operandEnabled,
                  decoration: InputDecoration(
                    labelText: operandEnabled ? 'Value' : 'Value not needed',
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final preset in _RulePreset.values)
                      ChoiceChip(
                        selected: _preset == preset,
                        label: Text(_presetLabel(preset)),
                        avatar: CircleAvatar(
                          radius: 8,
                          backgroundColor: _backgroundFor(preset),
                        ),
                        onSelected: (_) => setState(() => _preset = preset),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: selection == null ? null : () => _addRule(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Rule'),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Icon(
                      Icons.rule_folder_outlined,
                      color: KySheetColors.mutedText,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Rules',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      rules.length.toString(),
                      style: const TextStyle(
                        color: KySheetColors.mutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (rules.isEmpty)
                  const _EmptyRuleList()
                else
                  for (final rule in rules) _RuleTile(rule: rule),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addRule() {
    final selection = ref.read(selectedCellProvider);
    if (selection == null) return;

    final rule = ConditionalFormatRule(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      selection: selection,
      condition: _condition,
      operand: _condition == ConditionalFormatCondition.notEmpty
          ? ''
          : _operandController.text,
      backgroundColor: _backgroundFor(_preset),
      textColor: _textFor(_preset),
      bold: true,
    );

    ref.read(conditionalFormatRulesProvider.notifier).state = [
      ...ref.read(conditionalFormatRulesProvider),
      rule,
    ];
  }

  static String _conditionLabel(ConditionalFormatCondition condition) {
    return switch (condition) {
      ConditionalFormatCondition.greaterThan => 'Greater than',
      ConditionalFormatCondition.lessThan => 'Less than',
      ConditionalFormatCondition.equalTo => 'Equal to',
      ConditionalFormatCondition.containsText => 'Contains text',
      ConditionalFormatCondition.notEmpty => 'Not empty',
    };
  }

  static String _presetLabel(_RulePreset preset) {
    return switch (preset) {
      _RulePreset.green => 'Green',
      _RulePreset.amber => 'Amber',
      _RulePreset.red => 'Red',
      _RulePreset.blue => 'Blue',
    };
  }

  static Color _backgroundFor(_RulePreset preset) {
    return switch (preset) {
      _RulePreset.green => const Color(0xFFDCFCE7),
      _RulePreset.amber => const Color(0xFFFEF3C7),
      _RulePreset.red => const Color(0xFFFEE2E2),
      _RulePreset.blue => const Color(0xFFDBEAFE),
    };
  }

  static Color _textFor(_RulePreset preset) {
    return switch (preset) {
      _RulePreset.green => const Color(0xFF166534),
      _RulePreset.amber => const Color(0xFF92400E),
      _RulePreset.red => const Color(0xFF991B1B),
      _RulePreset.blue => const Color(0xFF1D4ED8),
    };
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.selectionLabel});

  final String selectionLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Row(
        children: [
          const Icon(Icons.format_color_fill, color: KySheetColors.accent),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Conditional Format',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
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

class _RuleTile extends ConsumerWidget {
  const _RuleTile({required this.rule});

  final ConditionalFormatRule rule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: rule.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: KySheetColors.gridLine),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              rule.label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: rule.textColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () {
              ref.read(conditionalFormatRulesProvider.notifier).state = [
                for (final existing in ref.read(conditionalFormatRulesProvider))
                  if (existing.id != rule.id) existing,
              ];
            },
            icon: Icon(Icons.close, color: rule.textColor, size: 18),
            tooltip: 'Remove Rule',
          ),
        ],
      ),
    );
  }
}

class _EmptyRuleList extends StatelessWidget {
  const _EmptyRuleList();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KySheetColors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: KySheetColors.gridLine),
      ),
      child: const Text(
        'No conditional format rules',
        style: TextStyle(
          color: KySheetColors.mutedText,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

enum _RulePreset { green, amber, red, blue }
