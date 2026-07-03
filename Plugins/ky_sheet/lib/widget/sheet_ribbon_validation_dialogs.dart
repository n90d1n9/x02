import 'package:flutter/material.dart';

import '../model/cell/cell_selection.dart';
import '../state/toolbar_provider.dart';

class SheetNumberValidationDialog extends StatefulWidget {
  const SheetNumberValidationDialog({
    super.key,
    required this.controller,
    required this.selection,
  });

  final ToolbarController controller;
  final CellSelection selection;

  @override
  State<SheetNumberValidationDialog> createState() =>
      _SheetNumberValidationDialogState();
}

class _SheetNumberValidationDialogState
    extends State<SheetNumberValidationDialog> {
  final _minController = TextEditingController();
  final _maxController = TextEditingController();

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Number Validation'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _minController,
            decoration: const InputDecoration(labelText: 'Minimum value'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _maxController,
            decoration: const InputDecoration(labelText: 'Maximum value'),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final min = double.tryParse(_minController.text);
            final max = double.tryParse(_maxController.text);
            widget.controller.applyNumberValidation(
              widget.selection,
              min: min,
              max: max,
            );
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class SheetListValidationDialog extends StatefulWidget {
  const SheetListValidationDialog({
    super.key,
    required this.controller,
    required this.selection,
  });

  final ToolbarController controller;
  final CellSelection selection;

  @override
  State<SheetListValidationDialog> createState() =>
      _SheetListValidationDialogState();
}

class _SheetListValidationDialogState extends State<SheetListValidationDialog> {
  final _optionsController = TextEditingController();

  @override
  void dispose() {
    _optionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('List Validation'),
      content: TextField(
        controller: _optionsController,
        decoration: const InputDecoration(
          labelText: 'Options (comma separated)',
          hintText: 'Yes,No,Maybe',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final options = _optionsController.text
                .split(',')
                .map((option) => option.trim())
                .where((option) => option.isNotEmpty)
                .toList();
            if (options.isNotEmpty) {
              widget.controller.applyListValidation(widget.selection, options);
            }
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
