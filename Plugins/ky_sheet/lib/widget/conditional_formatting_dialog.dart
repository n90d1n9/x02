/// Conditional Formatting Dialog
/// 
/// UI dialog for creating and editing conditional formatting rules.
/// Similar to Excel's Conditional Formatting Rules Manager.

import 'package:flutter/material.dart';
import '../model/conditional_formatting_rule.dart';

/// Dialog for managing conditional formatting rules
class ConditionalFormattingDialog extends StatefulWidget {
  final List<ConditionalFormattingRule>? existingRules;
  final String? rangeAddress;

  const ConditionalFormattingDialog({
    Key? key,
    this.existingRules,
    this.rangeAddress,
  }) : super(key: key);

  @override
  State<ConditionalFormattingDialog> createState() =>
      _ConditionalFormattingDialogState();
}

class _ConditionalFormattingDialogState
    extends State<ConditionalFormattingDialog> {
  late List<ConditionalFormattingRule> _rules;
  ConditionalFormattingRuleType _selectedType =
      ConditionalFormattingRuleType.cellValue;

  @override
  void initState() {
    super.initState();
    _rules = widget.existingRules ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Conditional Formatting Rules'),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Rule type selector
            DropdownButtonFormField<ConditionalFormattingRuleType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Rule Type',
                border: OutlineInputBorder(),
              ),
              items: ConditionalFormattingRuleType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getRuleTypeDisplayName(type)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Rule editor based on type
            Expanded(
              child: _buildRuleEditor(),
            ),
            
            const SizedBox(height: 16),
            
            // Existing rules list
            if (_rules.isNotEmpty) ...[
              const Divider(),
              const Text(
                'Existing Rules:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 2,
                child: ListView.builder(
                  itemCount: _rules.length,
                  itemBuilder: (context, index) {
                    final rule = _rules[index];
                    return Card(
                      child: ListTile(
                        title: Text(_getRuleDescription(rule)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editRule(rule),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteRule(rule),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => _addNewRule(),
          child: const Text('Add Rule'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_rules),
          child: const Text('OK'),
        ),
      ],
    );
  }

  Widget _buildRuleEditor() {
    switch (_selectedType) {
      case ConditionalFormattingRuleType.cellValue:
        return _buildCellValueRuleEditor();
      case ConditionalFormattingRuleType.formula:
        return _buildFormulaRuleEditor();
      case ConditionalFormattingRuleType.topBottom:
        return _buildTopBottomRuleEditor();
      case ConditionalFormattingRuleType.dataBar:
        return _buildDataBarRuleEditor();
      case ConditionalFormattingRuleType.colorScale:
        return _buildColorScaleRuleEditor();
      case ConditionalFormattingRuleType.iconSet:
        return _buildIconSetRuleEditor();
      case ConditionalFormattingRuleType.duplicateValues:
        return _buildDuplicateValueRuleEditor();
      case ConditionalFormattingRuleType.textContains:
        return _buildTextContainsRuleEditor();
      case ConditionalFormattingRuleType.dateOccurring:
        return _buildDateOccurringRuleEditor();
      case ConditionalFormattingRuleType.blankErrors:
        return _buildBlankErrorRuleEditor();
    }
  }

  Widget _buildCellValueRuleEditor() {
    ComparisonOperator _operator = ComparisonOperator.greaterThan;
    final _formula1Controller = TextEditingController();
    final _formula2Controller = TextEditingController();
    Color _fillColor = Colors.red.shade100;
    Color _fontColor = Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Format cells where:'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<ComparisonOperator>(
                value: _operator,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: ComparisonOperator.values.map((op) {
                  return DropdownMenuItem(
                    value: op,
                    child: Text(_getOperatorName(op)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _operator = value!;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _formula1Controller,
                decoration: const InputDecoration(
                  labelText: 'Value',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        if (_operator == ComparisonOperator.between ||
            _operator == ComparisonOperator.notBetween) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _formula2Controller,
            decoration: const InputDecoration(
              labelText: 'And',
              border: OutlineInputBorder(),
            ),
          ),
        ],
        const SizedBox(height: 16),
        const Text('Format:'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Fill Color:'),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _fillColor,
                          border: Border.all(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          final color = await ColorPickerDialog(
                            initialColor: _fillColor,
                          ).show(context);
                          if (color != null) {
                            setState(() {
                              _fillColor = color;
                            });
                          }
                        },
                        child: const Text('Choose'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Font Color:'),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _fontColor,
                          border: Border.all(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          final color = await ColorPickerDialog(
                            initialColor: _fontColor,
                          ).show(context);
                          if (color != null) {
                            setState(() {
                              _fontColor = color;
                            });
                          }
                        },
                        child: const Text('Choose'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormulaRuleEditor() {
    final _formulaController = TextEditingController();
    Color _fillColor = Colors.red.shade100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Enter formula:'),
        const SizedBox(height: 8),
        TextField(
          controller: _formulaController,
          decoration: const InputDecoration(
            hintText: 'e.g., =A1>B1 or =MOD(ROW(),2)=0',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        const Text('Format with fill color:'),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _fillColor,
                border: Border.all(color: Colors.grey),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () async {
                final color =
                    await ColorPickerDialog(initialColor: _fillColor).show(
                  context,
                );
                if (color != null) {
                  setState(() {
                    _fillColor = color;
                  });
                }
              },
              child: const Text('Choose Color'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopBottomRuleEditor() {
    TopBottomPosition _position = TopBottomPosition.top;
    TopBottomType _rankType = TopBottomType.items;
    final _rankValueController = TextEditingController(text: '10');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<TopBottomPosition>(
                value: _position,
                decoration: const InputDecoration(
                  labelText: 'Position',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: TopBottomPosition.top,
                    child: Text('Top'),
                  ),
                  DropdownMenuItem(
                    value: TopBottomPosition.bottom,
                    child: Text('Bottom'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _position = value!;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<TopBottomType>(
                value: _rankType,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: TopBottomType.items,
                    child: Text('Items'),
                  ),
                  DropdownMenuItem(
                    value: TopBottomType.percent,
                    child: Text('Percent'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _rankType = value!;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _rankValueController,
          decoration: InputDecoration(
            labelText: _rankType == TopBottomType.items ? 'N Items' : 'N Percent',
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildDataBarRuleEditor() {
    return const Center(
      child: Text('Data Bar configuration placeholder'),
    );
  }

  Widget _buildColorScaleRuleEditor() {
    return const Center(
      child: Text('Color Scale configuration placeholder'),
    );
  }

  Widget _buildIconSetRuleEditor() {
    return const Center(
      child: Text('Icon Set configuration placeholder'),
    );
  }

  Widget _buildDuplicateValueRuleEditor() {
    bool _highlightDuplicates = true;
    Color _fillColor = Colors.red.shade100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<bool>(
          value: _highlightDuplicates,
          decoration: const InputDecoration(
            labelText: 'Highlight',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(
              value: true,
              child: Text('Duplicate Values'),
            ),
            DropdownMenuItem(
              value: false,
              child: Text('Unique Values'),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _highlightDuplicates = value!;
            });
          },
        ),
        const SizedBox(height: 16),
        const Text('Format with fill color:'),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _fillColor,
                border: Border.all(color: Colors.grey),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () async {
                final color =
                    await ColorPickerDialog(initialColor: _fillColor).show(
                  context,
                );
                if (color != null) {
                  setState(() {
                    _fillColor = color;
                  });
                }
              },
              child: const Text('Choose Color'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextContainsRuleEditor() {
    final _textController = TextEditingController();
    bool _caseSensitive = false;
    Color _fillColor = Colors.red.shade100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _textController,
          decoration: const InputDecoration(
            labelText: 'Text',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('Case sensitive'),
          value: _caseSensitive,
          onChanged: (value) {
            setState(() {
              _caseSensitive = value!;
            });
          },
        ),
        const SizedBox(height: 16),
        const Text('Format with fill color:'),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _fillColor,
                border: Border.all(color: Colors.grey),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () async {
                final color =
                    await ColorPickerDialog(initialColor: _fillColor).show(
                  context,
                );
                if (color != null) {
                  setState(() {
                    _fillColor = color;
                  });
                }
              },
              child: const Text('Choose Color'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateOccurringRuleEditor() {
    String _period = 'today';

    return DropdownButtonFormField<String>(
      value: _period,
      decoration: const InputDecoration(
        labelText: 'Period',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'today', child: Text('Today')),
        DropdownMenuItem(value: 'yesterday', child: Text('Yesterday')),
        DropdownMenuItem(value: 'tomorrow', child: Text('Tomorrow')),
        DropdownMenuItem(value: 'last7Days', child: Text('Last 7 Days')),
        DropdownMenuItem(value: 'thisMonth', child: Text('This Month')),
        DropdownMenuItem(value: 'lastMonth', child: Text('Last Month')),
        DropdownMenuItem(value: 'nextMonth', child: Text('Next Month')),
      ],
      onChanged: (value) {
        setState(() {
          _period = value!;
        });
      },
    );
  }

  Widget _buildBlankErrorRuleEditor() {
    bool _blanks = true;
    Color _fillColor = Colors.red.shade100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<bool>(
          value: _blanks,
          decoration: const InputDecoration(
            labelText: 'Format',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(
              value: true,
              child: Text('Blank Cells'),
            ),
            DropdownMenuItem(
              value: false,
              child: Text('Error Values'),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _blanks = value!;
            });
          },
        ),
        const SizedBox(height: 16),
        const Text('Format with fill color:'),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _fillColor,
                border: Border.all(color: Colors.grey),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () async {
                final color =
                    await ColorPickerDialog(initialColor: _fillColor).show(
                  context,
                );
                if (color != null) {
                  setState(() {
                    _fillColor = color;
                  });
                }
              },
              child: const Text('Choose Color'),
            ),
          ],
        ),
      ],
    );
  }

  void _addNewRule() {
    // Create a new rule based on current editor state
    // This is simplified - full implementation would extract values from editors
    final newRule = CellValueRule(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      operator: ComparisonOperator.greaterThan,
      formula1: 0,
      fillColor: Colors.red.shade100,
    );

    setState(() {
      _rules.add(newRule);
    });
  }

  void _editRule(ConditionalFormattingRule rule) {
    // Open editor with existing rule values
    // Simplified for now
  }

  void _deleteRule(ConditionalFormattingRule rule) {
    setState(() {
      _rules.removeWhere((r) => r.id == rule.id);
    });
  }

  String _getRuleTypeDisplayName(ConditionalFormattingRuleType type) {
    switch (type) {
      case ConditionalFormattingRuleType.cellValue:
        return 'Cell Value';
      case ConditionalFormattingRuleType.formula:
        return 'Formula';
      case ConditionalFormattingRuleType.topBottom:
        return 'Top/Bottom Rules';
      case ConditionalFormattingRuleType.dataBar:
        return 'Data Bars';
      case ConditionalFormattingRuleType.colorScale:
        return 'Color Scales';
      case ConditionalFormattingRuleType.iconSet:
        return 'Icon Sets';
      case ConditionalFormattingRuleType.duplicateValues:
        return 'Duplicate/Unique Values';
      case ConditionalFormattingRuleType.textContains:
        return 'Text That Contains';
      case ConditionalFormattingRuleType.dateOccurring:
        return 'Dates Occurring';
      case ConditionalFormattingRuleType.blankErrors:
        return 'Blanks or Errors';
    }
  }

  String _getOperatorName(ComparisonOperator op) {
    switch (op) {
      case ComparisonOperator.between:
        return 'between';
      case ComparisonOperator.notBetween:
        return 'not between';
      case ComparisonOperator.equal:
        return '=';
      case ComparisonOperator.notEqual:
        return '<>';
      case ComparisonOperator.greaterThan:
        return '>';
      case ComparisonOperator.lessThan:
        return '<';
      case ComparisonOperator.greaterThanOrEqual:
        return '>=';
      case ComparisonOperator.lessThanOrEqual:
        return '<=';
    }
  }

  String _getRuleDescription(ConditionalFormattingRule rule) {
    if (rule is CellValueRule) {
      return 'Cell value ${_getOperatorName(rule.operator)} ${rule.formula1}';
    } else if (rule is FormulaRule) {
      return 'Formula: ${rule.formula}';
    } else if (rule is TopBottomRule) {
      return '${rule.position == TopBottomPosition.top ? 'Top' : 'Bottom'} ${rule.rankValue} ${rule.rankType == TopBottomType.items ? 'items' : '%'}';
    } else if (rule is DuplicateValueRule) {
      return rule.highlightDuplicates ? 'Duplicate values' : 'Unique values';
    } else if (rule is TextContainsRule) {
      return 'Text containing "${rule.text}"';
    } else {
      return rule.type.name;
    }
  }
}

/// Simple color picker dialog
class ColorPickerDialog {
  final Color initialColor;

  ColorPickerDialog({required this.initialColor});

  Future<Color?> show(BuildContext context) {
    return showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Color'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: Colors.primaries.length,
                itemBuilder: (context, index) {
                  final color = Colors.primaries[index];
                  return GestureDetector(
                    onTap: () => Navigator.of(context).pop(color),
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
