import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../states/layout_provider.dart';
import 'horizontal_ruler.dart';
import 'vertical_ruler.dart';

class DocumentRulerSystem extends ConsumerWidget {
  final Widget child;
  final double pageWidth;
  final double pageHeight;
  final ScrollController scrollController;

  const DocumentRulerSystem({
    super.key,
    required this.child,
    this.pageWidth = 816,
    this.pageHeight = 1056,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showRuler = ref.watch(rulerVisibilityProvider);
    final cursorPos = ref.watch(cursorPositionProvider);

    if (!showRuler) {
      return child;
    }

    return Stack(
      children: [
        // Vertical ruler on the left
        Positioned(
          left: 0,
          top: 30,
          bottom: 0,
          child: VerticalRuler(height: pageHeight, cursorY: cursorPos.dy),
        ),
        // Content with horizontal ruler
        Positioned(
          left: 30,
          right: 0,
          top: 0,
          bottom: 0,
          child: Column(
            children: [
              // Horizontal ruler on top
              HorizontalRuler(width: pageWidth, cursorX: cursorPos.dx),
              // Content
              Expanded(child: child),
            ],
          ),
        ),
        // Corner box
        Positioned(
          left: 0,
          top: 0,
          width: 30,
          height: 30,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border(
                right: BorderSide(color: Theme.of(context).dividerColor),
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Icon(
              Icons.crop_square,
              size: 16,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
        ),
      ],
    );
  }
}
