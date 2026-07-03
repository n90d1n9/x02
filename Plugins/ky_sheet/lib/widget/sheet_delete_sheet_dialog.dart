import 'package:flutter/material.dart';

import '../theme/ky_sheet_theme.dart';

class SheetDeleteSheetDialog extends StatelessWidget {
  const SheetDeleteSheetDialog({super.key, required this.sheetName});

  final String sheetName;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Sheet'),
      content: Text(
        'Delete "$sheetName"? This removes the sheet and its contents from the workbook.',
      ),
      actions: [
        TextButton(
          key: const ValueKey('ky-sheet-delete-sheet-cancel'),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          key: const ValueKey('ky-sheet-delete-sheet-confirm'),
          style: FilledButton.styleFrom(
            backgroundColor: KySheetColors.validationError,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          icon: const Icon(Icons.delete_outline, size: 18),
          label: const Text('Delete'),
        ),
      ],
    );
  }
}
