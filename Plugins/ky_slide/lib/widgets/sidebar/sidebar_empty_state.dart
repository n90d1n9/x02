import 'package:flutter/material.dart';

import 'sidebar_command_button.dart';

class SidebarEmptyState extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final IconData actionIcon;
  final VoidCallback? onAction;

  const SidebarEmptyState({
    super.key,
    required this.message,
    this.actionLabel,
    this.actionIcon = Icons.close,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final hasAction = actionLabel != null && onAction != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (hasAction) ...[
            const SizedBox(height: 9),
            SidebarCommandButton(
              icon: actionIcon,
              label: actionLabel!,
              isEnabled: true,
              onPressed: onAction!,
              height: 30,
              iconSize: 14,
            ),
          ],
        ],
      ),
    );
  }
}
