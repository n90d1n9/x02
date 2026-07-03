import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/chart_type.dart';
import '../../states/provider.dart';
import '../panel/document_panel_dropdown_field.dart';
import '../panel/document_panel_section_header.dart';
import '../panel/document_panel_text_field.dart';

/// Lets users configure a chart type and sample data before insertion.
class InsertChartDialog extends ConsumerStatefulWidget {
  static const chartTypeFieldKey = ValueKey('insert-chart-type-field');

  const InsertChartDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const InsertChartDialog(),
    );
  }

  @override
  ConsumerState<InsertChartDialog> createState() => _InsertChartDialogState();
}

class _InsertChartDialogState extends ConsumerState<InsertChartDialog> {
  final _titleController = TextEditingController(text: 'Chart Title');
  final _labelsController = TextEditingController(text: 'A, B, C, D');
  final _valuesController = TextEditingController(text: '10, 20, 15, 25');
  ChartType _selectedType = ChartType.bar;

  @override
  void dispose() {
    _titleController.dispose();
    _labelsController.dispose();
    _valuesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Insert Chart'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DocumentPanelSectionHeader(
                icon: Icons.insert_chart_outlined,
                title: 'Chart setup',
                description: 'Choose a visual style and title for the chart.',
              ),
              const SizedBox(height: 14),
              DocumentPanelTextField(
                controller: _titleController,
                labelText: 'Title',
                prefixIcon: Icons.title,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              DocumentPanelDropdownField<ChartType>(
                fieldKey: InsertChartDialog.chartTypeFieldKey,
                value: _selectedType,
                labelText: 'Chart type',
                prefixIcon: Icons.stacked_bar_chart,
                items: ChartType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_chartTypeLabel(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedType = value);
                },
              ),
              const SizedBox(height: 18),
              const DocumentPanelSectionHeader(
                icon: Icons.data_array_outlined,
                title: 'Data series',
                description:
                    'Enter matching comma-separated labels and values.',
              ),
              const SizedBox(height: 14),
              DocumentPanelTextField(
                controller: _labelsController,
                labelText: 'Labels (comma-separated)',
                hintText: 'A, B, C',
                prefixIcon: Icons.label_outline,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              DocumentPanelTextField(
                controller: _valuesController,
                labelText: 'Values (comma-separated)',
                hintText: '10, 20, 30',
                prefixIcon: Icons.numbers,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _insertChart, child: const Text('Insert')),
      ],
    );
  }

  String _chartTypeLabel(ChartType type) {
    return type.toString().split('.').last.toUpperCase();
  }

  void _insertChart() {
    try {
      final labels = _labelsController.text
          .split(',')
          .map((label) => label.trim())
          .toList();
      final values = _valuesController.text
          .split(',')
          .map((value) => double.tryParse(value.trim()) ?? 0)
          .toList();

      if (labels.length != values.length) {
        throw Exception('Labels and values count must match');
      }

      final messenger = ScaffoldMessenger.of(context);
      ref
          .read(documentProvider.notifier)
          .insertChart(_selectedType, _titleController.text, labels, values);
      Navigator.pop(context);
      messenger.showSnackBar(const SnackBar(content: Text('Chart inserted')));
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $error')));
    }
  }
}
