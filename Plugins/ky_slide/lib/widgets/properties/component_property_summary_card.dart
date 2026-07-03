import 'package:flutter/material.dart';

import '../../models/presentation_component.dart';

class ComponentPropertySummaryCard extends StatelessWidget {
  final PresentationComponent component;
  final Color accentColor;

  const ComponentPropertySummaryCard({
    super.key,
    required this.component,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            component.layerName ?? component.type.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _Metric(label: 'Type', value: component.type.name.toUpperCase()),
              _Metric(label: 'Z', value: component.zIndex.toString()),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _Metric(
                label: 'Position',
                value:
                    '${component.position.dx.round()}, ${component.position.dy.round()}',
              ),
              _Metric(
                label: 'Size',
                value:
                    '${component.size.width.round()} x ${component.size.height.round()}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
