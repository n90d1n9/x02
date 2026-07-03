import 'package:flutter/material.dart';

import '../theme/ky_sheet_theme.dart';

class SheetValidationDropdownButton extends StatelessWidget {
  const SheetValidationDropdownButton({
    super.key,
    required this.options,
    required this.onSelected,
  });

  final List<String> options;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Choose value',
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerUp: (event) => _showOptions(context, event.position),
        child: Container(
          width: 20,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: KySheetColors.surface,
            border: Border.all(color: KySheetColors.gridLineStrong),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            Icons.arrow_drop_down,
            size: 18,
            color: KySheetColors.mutedText,
          ),
        ),
      ),
    );
  }

  Future<void> _showOptions(BuildContext context, Offset globalPosition) async {
    final overlay = Overlay.maybeOf(context)?.context.findRenderObject();
    if (overlay is! RenderBox) return;

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(globalPosition.dx, globalPosition.dy, 0, 0),
        Offset.zero & overlay.size,
      ),
      items: [
        for (final option in options)
          PopupMenuItem(value: option, child: Text(option)),
      ],
    );

    if (selected != null) {
      onSelected(selected);
    }
  }
}
