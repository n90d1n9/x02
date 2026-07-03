import 'package:flutter/material.dart';

import '../../models/enums.dart';

class InteractivePreviewThumbnail extends StatelessWidget {
  final InteractiveType type;
  final Color accentColor;
  final Color secondaryColor;

  const InteractivePreviewThumbnail({
    super.key,
    required this.type,
    required this.accentColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xFF020617),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: accentColor.withValues(alpha: 0.34)),
        ),
        child: _buildPreview(),
      ),
    );
  }

  Widget _buildPreview() {
    return switch (type) {
      InteractiveType.poll => _OptionPreview(
        accentColor: accentColor,
        secondaryColor: secondaryColor,
        optionCount: 3,
      ),
      InteractiveType.quiz => _OptionPreview(
        accentColor: accentColor,
        secondaryColor: secondaryColor,
        optionCount: 2,
        showCheck: true,
      ),
      InteractiveType.countdown => _CountdownPreview(
        accentColor: accentColor,
        secondaryColor: secondaryColor,
      ),
      _ => _HotspotPreview(accentColor: accentColor),
    };
  }
}

class _HotspotPreview extends StatelessWidget {
  final Color accentColor;

  const _HotspotPreview({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.18),
          shape: BoxShape.circle,
          border: Border.all(color: accentColor.withValues(alpha: 0.78)),
        ),
        child: Icon(Icons.ads_click, color: accentColor, size: 13),
      ),
    );
  }
}

class _OptionPreview extends StatelessWidget {
  final Color accentColor;
  final Color secondaryColor;
  final int optionCount;
  final bool showCheck;

  const _OptionPreview({
    required this.accentColor,
    required this.secondaryColor,
    required this.optionCount,
    this.showCheck = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _line(accentColor, widthFactor: 0.62, height: 4),
        const SizedBox(height: 4),
        for (var index = 0; index < optionCount; index++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: index == optionCount - 1 ? 0 : 2,
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: index == 0
                          ? accentColor
                          : secondaryColor.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                    child: showCheck && index == 0
                        ? const Icon(Icons.check, color: Colors.white, size: 5)
                        : null,
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: _line(
                      Colors.white.withValues(alpha: 0.18),
                      widthFactor: index == 0 ? 0.9 : 0.72,
                      height: 5,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _line(
    Color color, {
    required double widthFactor,
    required double height,
  }) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

class _CountdownPreview extends StatelessWidget {
  final Color accentColor;
  final Color secondaryColor;

  const _CountdownPreview({
    required this.accentColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 27,
            height: 27,
            child: CircularProgressIndicator(
              value: 0.72,
              strokeWidth: 3,
              color: accentColor,
              backgroundColor: secondaryColor.withValues(alpha: 0.2),
            ),
          ),
          Text(
            '60',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.86),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
