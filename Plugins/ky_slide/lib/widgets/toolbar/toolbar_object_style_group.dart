import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'ribbon_menu_button.dart';
import 'toolbar_color_menu_button.dart';

const _precisionTolerance = 0.001;

/// Contextual ribbon group for selected-object quick visual styling.
class ToolbarObjectStyleGroup extends StatelessWidget {
  static const _borderWidths = [0.0, 1.0, 2.0, 4.0, 8.0];
  static const _opacityValues = [1.0, 0.75, 0.5, 0.25];

  final List<Color> colors;
  final Color? selectedFillColor;
  final Color? selectedBorderColor;
  final double selectedBorderWidth;
  final double selectedOpacity;
  final bool enabled;
  final bool compact;
  final ValueChanged<Color> onFillColorSelected;
  final VoidCallback onFillCleared;
  final ValueChanged<Color> onBorderColorSelected;
  final VoidCallback onBorderCleared;
  final ValueChanged<double> onBorderWidthSelected;
  final ValueChanged<double> onOpacitySelected;

  const ToolbarObjectStyleGroup({
    super.key,
    required this.colors,
    required this.selectedFillColor,
    required this.selectedBorderColor,
    required this.selectedBorderWidth,
    required this.selectedOpacity,
    required this.onFillColorSelected,
    required this.onFillCleared,
    required this.onBorderColorSelected,
    required this.onBorderCleared,
    required this.onBorderWidthSelected,
    required this.onOpacitySelected,
    this.enabled = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorChoices = _colorChoices();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ToolbarColorMenuButton(
          icon: Icons.format_color_fill,
          tooltip: 'Fill Color',
          menuLabelPrefix: 'Fill',
          colors: colorChoices,
          selectedColor: selectedFillColor,
          enabled: enabled,
          compact: compact,
          onSelected: onFillColorSelected,
          onCleared: onFillCleared,
          clearLabel: 'No Fill',
        ),
        ToolbarColorMenuButton(
          icon: Icons.border_color_outlined,
          tooltip: 'Stroke Color',
          menuLabelPrefix: 'Stroke',
          colors: colorChoices,
          selectedColor: selectedBorderColor,
          enabled: enabled,
          compact: compact,
          onSelected: onBorderColorSelected,
          onCleared: onBorderCleared,
          clearLabel: 'No Outline',
        ),
        RibbonMenuButton<double>(
          icon: Icons.line_weight,
          tooltip: 'Border Width',
          enabled: enabled,
          compact: compact,
          onSelected: onBorderWidthSelected,
          itemBuilder: (context) => [
            for (final width in _borderWidths)
              PopupMenuItem(
                value: width,
                child: _ValueMenuRow(
                  icon: Icons.line_weight,
                  label: _borderWidthLabel(width),
                  selected:
                      (selectedBorderWidth - width).abs() < _precisionTolerance,
                ),
              ),
          ],
        ),
        RibbonMenuButton<double>(
          icon: Icons.opacity,
          tooltip: 'Opacity',
          enabled: enabled,
          compact: compact,
          onSelected: onOpacitySelected,
          itemBuilder: (context) => [
            for (final opacity in _opacityValues)
              PopupMenuItem(
                value: opacity,
                child: _ValueMenuRow(
                  icon: Icons.opacity,
                  label: _opacityLabel(opacity),
                  selected:
                      (selectedOpacity - opacity).abs() < _precisionTolerance,
                ),
              ),
          ],
        ),
      ],
    );
  }

  List<Color> _colorChoices() {
    final seeded = <Color>[
      ?selectedFillColor,
      ?selectedBorderColor,
      ...colors,
      const Color(0xFFFFFFFF),
      const Color(0xFF0F172A),
    ];

    final seen = <int>{};
    return [
      for (final color in seeded)
        if (seen.add(color.toARGB32())) color,
    ].take(8).toList();
  }

  String _borderWidthLabel(double width) {
    if (width == 0) return 'No border';
    return '${width.toStringAsFixed(width.truncateToDouble() == width ? 0 : 1)} px';
  }

  String _opacityLabel(double opacity) {
    return '${(opacity * 100).round()}%';
  }
}

/// Popup menu row for contextual style values.
class _ValueMenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;

  const _ValueMenuRow({
    required this.icon,
    required this.label,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          selected ? Icons.check_circle : icon,
          color: selected ? const Color(0xFF38BDF8) : Colors.white70,
          size: 18,
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

@Preview(name: 'Toolbar object style group', size: Size(250, 88))
Widget toolbarObjectStyleGroupPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: Center(
        child: ToolbarObjectStyleGroup(
          colors: const [Color(0xFF38BDF8), Color(0xFF14B8A6)],
          selectedFillColor: const Color(0xFF38BDF8),
          selectedBorderColor: const Color(0xFF14B8A6),
          selectedBorderWidth: 2,
          selectedOpacity: 1,
          onFillColorSelected: (_) {},
          onFillCleared: () {},
          onBorderColorSelected: (_) {},
          onBorderCleared: () {},
          onBorderWidthSelected: (_) {},
          onOpacitySelected: (_) {},
        ),
      ),
    ),
  );
}
