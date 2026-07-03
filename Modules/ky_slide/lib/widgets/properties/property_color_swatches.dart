import 'package:flutter/material.dart';

class PropertyColorSwatches extends StatelessWidget {
  final List<Color> colors;
  final Color? selectedColor;
  final bool enabled;
  final ValueChanged<Color> onSelected;

  const PropertyColorSwatches({
    super.key,
    required this.colors,
    required this.onSelected,
    this.selectedColor,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final color in colors)
          Tooltip(
            message: _labelFor(color),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: enabled ? () => onSelected(color) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: enabled ? color : color.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selectedColor == color
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.18),
                    width: selectedColor == color ? 2 : 1,
                  ),
                  boxShadow: selectedColor == color
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _labelFor(Color color) {
    final value = color.toARGB32().toRadixString(16).padLeft(8, '0');
    return '#${value.substring(2).toUpperCase()}';
  }
}
