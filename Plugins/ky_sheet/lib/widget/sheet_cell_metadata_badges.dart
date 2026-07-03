import 'package:flutter/material.dart';

import '../theme/ky_sheet_theme.dart';

class SheetCellMetadataBadges extends StatelessWidget {
  const SheetCellMetadataBadges({super.key, this.comment, this.hyperlink});

  final String? comment;
  final String? hyperlink;

  bool get hasComment => comment?.trim().isNotEmpty ?? false;
  bool get hasHyperlink => hyperlink?.trim().isNotEmpty ?? false;
  bool get isEmpty => !hasComment && !hasHyperlink;

  int get count => (hasComment ? 1 : 0) + (hasHyperlink ? 1 : 0);

  @override
  Widget build(BuildContext context) {
    if (isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasHyperlink)
          _MetadataBadge(
            icon: Icons.link,
            color: KySheetColors.accent,
            tooltip: hyperlink!.trim(),
          ),
        if (hasComment)
          _MetadataBadge(
            icon: Icons.comment,
            color: KySheetColors.comment,
            tooltip: comment!.trim(),
          ),
      ],
    );
  }
}

class _MetadataBadge extends StatelessWidget {
  const _MetadataBadge({
    required this.icon,
    required this.color,
    required this.tooltip,
  });

  final IconData icon;
  final Color color;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 350),
      child: Padding(
        padding: const EdgeInsets.only(left: 2),
        child: Icon(icon, size: 13, color: color),
      ),
    );
  }
}
