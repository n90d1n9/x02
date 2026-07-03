import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// Non-interactive hover outline and label for objects under the pointer.
class ComponentHoverOverlay extends StatelessWidget {
  final String label;
  final String typeLabel;
  final bool isLocked;
  final Color accentColor;

  const ComponentHoverOverlay({
    super.key,
    required this.label,
    required this.typeLabel,
    required this.isLocked,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final outlineColor = isLocked ? const Color(0xFFF59E0B) : accentColor;

    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: outlineColor.withValues(alpha: 0.78),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: outlineColor.withValues(alpha: 0.16),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: -30,
              child: _ComponentHoverLabel(
                label: label,
                typeLabel: typeLabel,
                isLocked: isLocked,
                accentColor: outlineColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact object-name pill used by the canvas hover overlay.
class _ComponentHoverLabel extends StatelessWidget {
  final String label;
  final String typeLabel;
  final bool isLocked;
  final Color accentColor;

  const _ComponentHoverLabel({
    required this.label,
    required this.typeLabel,
    required this.isLocked,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 230),
      child: Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: accentColor.withValues(alpha: 0.36)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLocked ? Icons.lock_outline : Icons.near_me_outlined,
              size: 13,
              color: accentColor,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              typeLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@Preview(name: 'Component hover overlay', size: Size(260, 140))
Widget componentHoverOverlayPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF101114),
      body: Center(
        child: SizedBox(
          width: 180,
          height: 72,
          child: Stack(
            clipBehavior: Clip.none,
            children: const [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Color(0xFF1E293B)),
                ),
              ),
              ComponentHoverOverlay(
                label: 'Revenue card',
                typeLabel: 'Rectangle',
                isLocked: false,
                accentColor: Color(0xFF38BDF8),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
