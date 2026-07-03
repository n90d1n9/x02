import 'package:flutter/material.dart';

/// Shows why a command palette action is currently unavailable.
class DocumentCommandAvailabilityBadge extends StatelessWidget {
  final String label;
  final String? reason;
  final IconData icon;

  const DocumentCommandAvailabilityBadge({
    super.key,
    required this.label,
    this.reason,
    this.icon = Icons.lock_outline,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.72),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );

    if (reason == null || reason!.trim().isEmpty) return badge;
    return Tooltip(message: reason!, child: badge);
  }
}
