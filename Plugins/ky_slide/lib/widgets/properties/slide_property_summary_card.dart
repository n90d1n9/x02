import 'package:flutter/material.dart';

import '../../models/presentation.dart';
import '../../models/slide.dart';

class SlidePropertySummaryCard extends StatelessWidget {
  final Presentation presentation;
  final Slide slide;

  const SlidePropertySummaryCard({
    super.key,
    required this.presentation,
    required this.slide,
  });

  @override
  Widget build(BuildContext context) {
    final slideNumber = presentation.currentSlideIndex + 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: presentation.theme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: presentation.theme.primaryColor.withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            slide.title ?? 'Slide $slideNumber',
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
              _Metric(
                label: 'Slide',
                value: '$slideNumber / ${presentation.slides.length}',
              ),
              _Metric(
                label: 'Objects',
                value: slide.components.length.toString(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _Metric(label: 'Transition', value: slide.transition.name),
              _Metric(
                label: 'Canvas',
                value:
                    '${presentation.slideSize.width.round()} x ${presentation.slideSize.height.round()}',
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
