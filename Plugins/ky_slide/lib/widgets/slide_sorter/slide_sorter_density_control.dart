import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/slide_sorter_density.dart';

/// Icon segmented control for adjusting slide board thumbnail density.
class SlideSorterDensityControl extends StatelessWidget {
  final SlideSorterDensity value;
  final ValueChanged<SlideSorterDensity> onChanged;
  final Color accentColor;

  const SlideSorterDensityControl({
    super.key,
    required this.value,
    required this.onChanged,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DensitySegment(
            density: SlideSorterDensity.compact,
            value: value,
            icon: Icons.grid_view,
            tooltip: 'Compact slide grid',
            accentColor: accentColor,
            onChanged: onChanged,
          ),
          _DensitySegment(
            density: SlideSorterDensity.balanced,
            value: value,
            icon: Icons.view_module,
            tooltip: 'Balanced slide grid',
            accentColor: accentColor,
            onChanged: onChanged,
          ),
          _DensitySegment(
            density: SlideSorterDensity.roomy,
            value: value,
            icon: Icons.crop_16_9,
            tooltip: 'Roomy slide grid',
            accentColor: accentColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// One icon segment in the slide board density control.
class _DensitySegment extends StatelessWidget {
  final SlideSorterDensity density;
  final SlideSorterDensity value;
  final IconData icon;
  final String tooltip;
  final Color accentColor;
  final ValueChanged<SlideSorterDensity> onChanged;

  const _DensitySegment({
    required this.density,
    required this.value,
    required this.icon,
    required this.tooltip,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = density == value;
    final foregroundColor = selected ? _activeForegroundColor : Colors.white60;

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        selected: selected,
        label: tooltip,
        child: Material(
          color: selected ? accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: selected ? null : () => onChanged(density),
            child: SizedBox(
              width: 30,
              height: 28,
              child: Icon(icon, size: 15, color: foregroundColor),
            ),
          ),
        ),
      ),
    );
  }

  Color get _activeForegroundColor {
    final brightness = ThemeData.estimateBrightnessForColor(accentColor);
    return brightness == Brightness.dark ? Colors.white : Colors.black;
  }
}

@Preview(name: 'Slide sorter density control', size: Size(180, 80))
Widget slideSorterDensityControlPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SlideSorterDensityControl(
          value: SlideSorterDensity.balanced,
          accentColor: const Color(0xFF38BDF8),
          onChanged: (_) {},
        ),
      ),
    ),
  );
}
