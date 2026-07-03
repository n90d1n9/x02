import 'package:flutter/material.dart';

import '../theme/ky_sheet_theme.dart';
import 'sheet_tab_color_picker.dart';

/// Dialog result that distinguishes clearing tab color from cancelling.
class SheetTabColorSelection {
  const SheetTabColorSelection(this.color);

  /// Selected tab color, or null when the color should be cleared.
  final Color? color;
}

/// Dialog for assigning a color marker to a workbook sheet tab.
class SheetTabColorDialog extends StatelessWidget {
  const SheetTabColorDialog({
    super.key,
    required this.sheetName,
    this.currentColor,
    this.options = SheetTabColorPicker.defaultOptions,
  });

  /// Sheet name shown in the dialog header.
  final String sheetName;

  /// Currently applied sheet tab color.
  final Color? currentColor;

  /// Color options displayed in the picker.
  final List<SheetTabColorOption> options;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.palette_outlined,
                    size: 20,
                    color: KySheetColors.accent,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tab Color',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: KySheetColors.text,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        Text(
                          sheetName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: KySheetColors.mutedText,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SheetTabColorPicker(
                currentColor: currentColor,
                options: options,
                onSelected: (color) =>
                    Navigator.of(context).pop(SheetTabColorSelection(color)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
