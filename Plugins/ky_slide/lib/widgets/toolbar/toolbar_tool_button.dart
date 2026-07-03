import 'package:flutter/material.dart';

class ToolbarToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Gradient gradient;
  final VoidCallback onPressed;
  final bool compact;

  const ToolbarToolButton({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.gradient,
    required this.onPressed,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                gradient: isSelected ? gradient : null,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? null
                    : Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: compact ? 22 : 24,
                    color: isSelected ? Colors.white : Colors.white54,
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected ? Colors.white : Colors.white54,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
