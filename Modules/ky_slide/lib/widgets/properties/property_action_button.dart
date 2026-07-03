import 'package:flutter/material.dart';

class PropertyActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? tooltip;
  final bool enabled;
  final VoidCallback onPressed;

  const PropertyActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.tooltip,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: 16),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        style: TextButton.styleFrom(
          foregroundColor: enabled ? Colors.white70 : Colors.white30,
          backgroundColor: enabled
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.025),
          minimumSize: const Size.fromHeight(40),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
      ),
    );

    if (tooltip == null) return content;

    return Tooltip(message: tooltip!, child: content);
  }
}
