import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/slide_navigator_density.dart';

/// Segmented density picker for the slide navigator thumbnail rail.
class SlideNavigatorDensityControl extends StatelessWidget {
  final SlideNavigatorDensity density;
  final ValueChanged<SlideNavigatorDensity> onSelected;
  final Color accentColor;

  const SlideNavigatorDensityControl({
    super.key,
    required this.density,
    required this.onSelected,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DensitySegment(
            icon: Icons.view_agenda,
            density: SlideNavigatorDensity.compact,
            selected: density == SlideNavigatorDensity.compact,
            accentColor: accentColor,
            onSelected: onSelected,
          ),
          _DensityDivider(accentColor: accentColor),
          _DensitySegment(
            icon: Icons.view_stream,
            density: SlideNavigatorDensity.comfortable,
            selected: density == SlideNavigatorDensity.comfortable,
            accentColor: accentColor,
            onSelected: onSelected,
          ),
        ],
      ),
    );
  }
}

/// Individual icon segment used by the thumbnail density picker.
class _DensitySegment extends StatelessWidget {
  final IconData icon;
  final SlideNavigatorDensity density;
  final bool selected;
  final Color accentColor;
  final ValueChanged<SlideNavigatorDensity> onSelected;

  const _DensitySegment({
    required this.icon,
    required this.density,
    required this.selected,
    required this.accentColor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : Colors.white60;

    return Tooltip(
      message: density.tooltip,
      child: Semantics(
        button: true,
        selected: selected,
        label: density.tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(7),
          onTap: () => onSelected(density),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            width: 30,
            height: 28,
            decoration: BoxDecoration(
              color: selected
                  ? accentColor.withValues(alpha: 0.24)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
              border: selected
                  ? Border.all(color: accentColor.withValues(alpha: 0.42))
                  : null,
            ),
            child: Icon(icon, size: 15, color: foreground),
          ),
        ),
      ),
    );
  }
}

/// Hairline divider between slide navigator density segments.
class _DensityDivider extends StatelessWidget {
  final Color accentColor;

  const _DensityDivider({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 18,
      color: accentColor.withValues(alpha: 0.18),
    );
  }
}

@Preview(name: 'Slide navigator density control', size: Size(150, 80))
Widget slideNavigatorDensityControlPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SlideNavigatorDensityControl(
          density: SlideNavigatorDensity.comfortable,
          accentColor: const Color(0xFF38BDF8),
          onSelected: (_) {},
        ),
      ),
    ),
  );
}
