import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/canvas_grid_preset.dart';

/// Ribbon popup for selecting the canvas grid density used by grid and snap.
class ToolbarGridPresetMenu extends StatelessWidget {
  final CanvasGridPreset selectedPreset;
  final ValueChanged<CanvasGridPreset> onSelected;
  final bool compact;

  const ToolbarGridPresetMenu({
    super.key,
    required this.selectedPreset,
    required this.onSelected,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final width = compact ? 42.0 : 58.0;
    final height = compact ? 42.0 : 58.0;

    return PopupMenuButton<CanvasGridPreset>(
      tooltip: 'Grid spacing',
      color: const Color(0xFF111827),
      elevation: 10,
      offset: const Offset(0, 8),
      onSelected: onSelected,
      itemBuilder: (context) {
        return CanvasGridPreset.values.map((preset) {
          return PopupMenuItem<CanvasGridPreset>(
            value: preset,
            child: _GridPresetMenuItem(
              preset: preset,
              isSelected: preset == selectedPreset,
            ),
          );
        }).toList();
      },
      child: Tooltip(
        message: 'Grid spacing',
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.grid_4x4, size: 16, color: Color(0xFF38BDF8)),
              const SizedBox(height: 3),
              Text(
                selectedPreset.spacingLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: compact ? 10 : 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single row in the grid preset popup.
class _GridPresetMenuItem extends StatelessWidget {
  final CanvasGridPreset preset;
  final bool isSelected;

  const _GridPresetMenuItem({required this.preset, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 164,
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.check : Icons.grid_4x4,
            size: 16,
            color: isSelected ? const Color(0xFF38BDF8) : Colors.white38,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              preset.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
          Text(
            preset.spacingLabel,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

@Preview(name: 'Toolbar grid preset menu', size: Size(180, 96))
Widget toolbarGridPresetMenuPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: Center(
        child: ToolbarGridPresetMenu(
          selectedPreset: CanvasGridPreset.comfortable,
          onSelected: (_) {},
        ),
      ),
    ),
  );
}
