import 'package:flutter/material.dart';

import '../../models/slide_layout.dart';

class SlideLayoutPreviewThumbnail extends StatelessWidget {
  final SlideLayoutType type;
  final Color accentColor;

  const SlideLayoutPreviewThumbnail({
    super.key,
    required this.type,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF020617),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: accentColor.withValues(alpha: 0.36)),
        ),
        child: _buildPreview(),
      ),
    );
  }

  Widget _buildPreview() {
    switch (type) {
      case SlideLayoutType.blank:
        return Center(
          child: Container(
            width: 14,
            height: 9,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
          ),
        );
      case SlideLayoutType.title:
        return Center(
          child: FractionallySizedBox(
            widthFactor: 0.78,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _line(widthFactor: 0.9, height: 4, alignment: Alignment.center),
                const SizedBox(height: 3),
                _line(
                  widthFactor: 0.62,
                  height: 2.5,
                  alignment: Alignment.center,
                  color: Colors.white.withValues(alpha: 0.42),
                ),
              ],
            ),
          ),
        );
      case SlideLayoutType.titleAndContent:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _line(widthFactor: 0.66, height: 4),
            const SizedBox(height: 4),
            Expanded(child: _placeholder(accentColor)),
          ],
        );
      case SlideLayoutType.twoColumn:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _line(widthFactor: 0.62, height: 4),
            const SizedBox(height: 4),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _placeholder(accentColor)),
                  const SizedBox(width: 4),
                  Expanded(child: _placeholder(Colors.white)),
                ],
              ),
            ),
          ],
        );
      case SlideLayoutType.sectionHeader:
        return Center(
          child: FractionallySizedBox(
            widthFactor: 0.76,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _line(
                  widthFactor: 0.82,
                  height: 4,
                  alignment: Alignment.center,
                ),
                const SizedBox(height: 3),
                _line(
                  widthFactor: 0.52,
                  height: 2.5,
                  alignment: Alignment.center,
                  color: accentColor,
                ),
              ],
            ),
          ),
        );
      case SlideLayoutType.comparison:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _line(widthFactor: 0.58, height: 4),
            const SizedBox(height: 4),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _comparisonColumn(accentColor)),
                  const SizedBox(width: 4),
                  Expanded(child: _comparisonColumn(Colors.white)),
                ],
              ),
            ),
          ],
        );
    }
  }

  Widget _comparisonColumn(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _line(widthFactor: 0.72, height: 3, color: color),
        const SizedBox(height: 3),
        Expanded(child: _placeholder(color)),
      ],
    );
  }

  Widget _placeholder(Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: color == Colors.white ? 0.08 : 0.16),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: color.withValues(alpha: color == Colors.white ? 0.16 : 0.34),
        ),
      ),
    );
  }

  Widget _line({
    required double widthFactor,
    required double height,
    Alignment alignment = Alignment.centerLeft,
    Color? color,
  }) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: alignment,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color ?? Colors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}
