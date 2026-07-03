import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/component.dart';
import '../../models/presentation_component.dart';

/// Compact status-bar readout for the selected object's frame and rotation.
class EditorSelectionGeometryChip extends StatelessWidget {
  final PresentationComponent component;
  final Color accentColor;
  final bool compact;

  const EditorSelectionGeometryChip({
    super.key,
    required this.component,
    this.accentColor = const Color(0xFF38BDF8),
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Selection geometry',
      child: Container(
        width: compact ? 174 : 218,
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: accentColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.aspect_ratio, size: 14, color: accentColor),
            const SizedBox(width: 7),
            _GeometryMetric(label: _sizeLabel()),
            const SizedBox(width: 8),
            _GeometryMetric(label: _positionLabel()),
            if (!compact) ...[
              const SizedBox(width: 8),
              _GeometryMetric(label: _rotationLabel()),
            ],
          ],
        ),
      ),
    );
  }

  String _sizeLabel() {
    return '${component.size.width.round()} x ${component.size.height.round()}';
  }

  String _positionLabel() {
    return 'X ${component.position.dx.round()} Y ${component.position.dy.round()}';
  }

  String _rotationLabel() {
    return '${component.rotation.round()} deg';
  }
}

/// Single clipped metric label inside the selection geometry chip.
class _GeometryMetric extends StatelessWidget {
  final String label;

  const _GeometryMetric({required this.label});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          height: 1,
        ),
      ),
    );
  }
}

@Preview(name: 'Editor selection geometry chip', size: Size(260, 80))
Widget editorSelectionGeometryChipPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: EditorSelectionGeometryChip(
          component: PresentationComponent(
            id: 'geometry-preview',
            type: ComponentType.shape,
            position: const Offset(42, 56),
            size: const Size(240, 120),
            rotation: 15,
          ),
        ),
      ),
    ),
  );
}
