import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/component.dart';
import '../../models/presentation_component.dart';

/// Compact ribbon summary of the selected object's key formatting state.
class ToolbarFormatSummary extends StatelessWidget {
  final PresentationComponent component;
  final Color accentColor;
  final bool compact;

  const ToolbarFormatSummary({
    super.key,
    required this.component,
    required this.accentColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final fillColor = component.backgroundColor;
    final border = component.border;
    final hasOutline = border != null && border.width > 0;

    return Tooltip(
      message: 'Selected object format summary',
      child: Container(
        width: compact ? 196 : 224,
        height: compact ? 48 : 50,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accentColor.withValues(alpha: 0.24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_iconFor(component.type), color: Colors.white70, size: 14),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    _typeLabel(component.type),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                      height: 1,
                    ),
                  ),
                ),
                _SummaryText(_sizeLabel()),
                const SizedBox(width: 6),
                _SummaryText('${component.rotation.round()} deg'),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                _ColorMetric(
                  label: fillColor == null ? 'No fill' : 'Fill',
                  color: fillColor,
                ),
                const SizedBox(width: 7),
                _ColorMetric(
                  label: hasOutline
                      ? '${border.width.toStringAsFixed(border.width == border.width.roundToDouble() ? 0 : 1)} px'
                      : 'No outline',
                  color: hasOutline ? border.color : null,
                ),
                const SizedBox(width: 7),
                _SummaryText('${(component.opacity * 100).round()}%'),
                const Spacer(),
                _GlowPill(
                  enabled: component.hasGlow,
                  color: component.glowColor ?? accentColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _sizeLabel() {
    return '${component.size.width.round()} x ${component.size.height.round()}';
  }

  String _typeLabel(ComponentType type) {
    return switch (type) {
      ComponentType.richText => 'Text',
      ComponentType.image => 'Image',
      ComponentType.chart => 'Chart',
      ComponentType.video => 'Video',
      ComponentType.audio => 'Audio',
      ComponentType.hotspot ||
      ComponentType.poll ||
      ComponentType.quiz ||
      ComponentType.countdown ||
      ComponentType.progressBar => 'Interactive',
      ComponentType.shape ||
      ComponentType.circle ||
      ComponentType.triangle => 'Shape',
      _ => 'Object',
    };
  }

  IconData _iconFor(ComponentType type) {
    return switch (type) {
      ComponentType.richText => Icons.text_fields,
      ComponentType.image => Icons.image_outlined,
      ComponentType.chart => Icons.bar_chart,
      ComponentType.video => Icons.videocam_outlined,
      ComponentType.audio => Icons.graphic_eq,
      ComponentType.hotspot ||
      ComponentType.poll ||
      ComponentType.quiz ||
      ComponentType.countdown ||
      ComponentType.progressBar => Icons.touch_app_outlined,
      ComponentType.circle => Icons.circle_outlined,
      ComponentType.triangle => Icons.change_history,
      _ => Icons.crop_square,
    };
  }
}

/// Short text metric used by the ribbon format summary.
class _SummaryText extends StatelessWidget {
  final String label;

  const _SummaryText(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
        height: 1,
      ),
    );
  }
}

/// Color-bearing metric for fill and outline values.
class _ColorMetric extends StatelessWidget {
  final String label;
  final Color? color;

  const _ColorMetric({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ColorDot(color: color),
          const SizedBox(width: 4),
          Flexible(child: _SummaryText(label)),
        ],
      ),
    );
  }
}

/// Small circular color indicator for summary chips.
class _ColorDot extends StatelessWidget {
  final Color? color;

  const _ColorDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: color ?? Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: color == null
              ? Colors.white.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.22),
        ),
      ),
      child: color == null
          ? Icon(
              Icons.close,
              size: 6,
              color: Colors.white.withValues(alpha: 0.5),
            )
          : null,
    );
  }
}

/// Glow state pill used by the compact format summary.
class _GlowPill extends StatelessWidget {
  final bool enabled;
  final Color color;

  const _GlowPill({required this.enabled, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: enabled
            ? color.withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: enabled
              ? color.withValues(alpha: 0.42)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Text(
        enabled ? 'Glow' : 'No glow',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: enabled ? Colors.white : Colors.white38,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
          height: 1,
        ),
      ),
    );
  }
}

@Preview(name: 'Toolbar format summary', size: Size(260, 86))
Widget toolbarFormatSummaryPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: Center(
        child: ToolbarFormatSummary(
          accentColor: const Color(0xFF38BDF8),
          component: PresentationComponent(
            id: 'summary-preview',
            type: ComponentType.shape,
            position: const Offset(40, 40),
            size: const Size(240, 120),
            backgroundColor: const Color(0xFF38BDF8),
            border: const BorderSide(color: Color(0xFF14B8A6), width: 2),
            rotation: 15,
            opacity: 0.75,
            hasGlow: true,
            glowColor: const Color(0xFF14B8A6),
          ),
        ),
      ),
    ),
  );
}
