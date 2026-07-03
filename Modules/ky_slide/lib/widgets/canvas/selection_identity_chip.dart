import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/component.dart';
import '../../models/selection_identity.dart';

/// Compact identity chip that labels the selected object near canvas actions.
class SelectionIdentityChip extends StatelessWidget {
  static const double visualWidth = 156;
  static const double visualHeight = 40;

  final SelectionIdentity identity;
  final Color accentColor;

  const SelectionIdentityChip({
    super.key,
    required this.identity,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${identity.typeLabel} ${identity.title}, ${identity.stateLabel}',
      child: Container(
        width: visualWidth,
        height: visualHeight,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF020617).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accentColor.withValues(alpha: 0.34)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.24),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: accentColor.withValues(alpha: 0.24)),
              ),
              child: Icon(
                _iconFor(identity.type),
                size: 15,
                color: accentColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    identity.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${identity.typeLabel} / ${identity.stateLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            if (identity.isLocked) ...[
              const SizedBox(width: 6),
              const Icon(Icons.lock_outline, color: Colors.white38, size: 13),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconFor(ComponentType type) {
    return switch (type) {
      ComponentType.richText => Icons.title,
      ComponentType.image || ComponentType.gif => Icons.image_outlined,
      ComponentType.shape ||
      ComponentType.circle ||
      ComponentType.triangle => Icons.category_outlined,
      ComponentType.chart => Icons.insert_chart_outlined,
      ComponentType.video => Icons.movie_outlined,
      ComponentType.audio => Icons.graphic_eq,
      ComponentType.hotspot ||
      ComponentType.poll ||
      ComponentType.quiz ||
      ComponentType.countdown ||
      ComponentType.progressBar => Icons.touch_app_outlined,
      ComponentType.diagram => Icons.account_tree_outlined,
      ComponentType.icon => Icons.star_border,
      ComponentType.lottie ||
      ComponentType.particles ||
      ComponentType.gradient => Icons.auto_awesome_outlined,
      ComponentType.unknown => Icons.crop_square,
    };
  }
}

@Preview(name: 'Selection identity chip', size: Size(220, 96))
Widget selectionIdentityChipPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF101114),
      body: Center(
        child: SelectionIdentityChip(
          accentColor: const Color(0xFF38BDF8),
          identity: const SelectionIdentity(
            title: 'Quarterly update',
            typeLabel: 'Text',
            type: ComponentType.richText,
            isLocked: false,
            isVisible: true,
          ),
        ),
      ),
    ),
  );
}
