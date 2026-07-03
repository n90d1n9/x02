import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widget_previews.dart';

import '../../states/component_provider.dart';
import '../../states/editor_view_provider.dart';
import '../../states/presentation_provider.dart';

/// Scrollable, zoom-aware viewport that centers the slide stage in the canvas.
class SlideCanvasViewport extends ConsumerStatefulWidget {
  final Widget child;

  const SlideCanvasViewport({super.key, required this.child});

  @override
  ConsumerState<SlideCanvasViewport> createState() =>
      _SlideCanvasViewportState();
}

/// State holder for canvas scroll controllers and published viewport metrics.
class _SlideCanvasViewportState extends ConsumerState<SlideCanvasViewport> {
  static const double _stagePadding = 48;

  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  Size _lastViewportSize = Size.zero;

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final presentation = ref.watch(presentationProvider);
    final zoom = ref.watch(zoomLevelProvider);
    final slideSize = presentation.slideSize;
    final scaledSlideSize = Size(
      slideSize.width * zoom,
      slideSize.height * zoom,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
        _publishViewportSize(viewportSize);

        final stageWidth = math.max(
          viewportSize.width,
          scaledSlideSize.width + (_stagePadding * 2),
        );
        final stageHeight = math.max(
          viewportSize.height,
          scaledSlideSize.height + (_stagePadding * 2),
        );

        return Container(
          color: const Color(0xFF101114),
          child: Scrollbar(
            controller: _verticalController,
            thumbVisibility: false,
            child: SingleChildScrollView(
              controller: _verticalController,
              child: Scrollbar(
                controller: _horizontalController,
                notificationPredicate: (notification) =>
                    notification.depth == 1,
                thumbVisibility: false,
                child: SingleChildScrollView(
                  controller: _horizontalController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: stageWidth,
                    height: stageHeight,
                    child: Center(
                      child: _ScaledCanvasStage(
                        slideSize: slideSize,
                        scaledSlideSize: scaledSlideSize,
                        zoom: zoom,
                        child: widget.child,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _publishViewportSize(Size size) {
    if (_lastViewportSize == size) return;

    _lastViewportSize = size;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(canvasViewportSizeProvider.notifier).state = size;
    });
  }
}

/// Applies the current zoom transform while preserving the slide's layout size.
class _ScaledCanvasStage extends StatelessWidget {
  final Size slideSize;
  final Size scaledSlideSize;
  final double zoom;
  final Widget child;

  const _ScaledCanvasStage({
    required this.slideSize,
    required this.scaledSlideSize,
    required this.zoom,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: scaledSlideSize.width,
      height: scaledSlideSize.height,
      child: OverflowBox(
        alignment: Alignment.topLeft,
        minWidth: slideSize.width,
        maxWidth: slideSize.width,
        minHeight: slideSize.height,
        maxHeight: slideSize.height,
        child: Transform.scale(
          alignment: Alignment.topLeft,
          scale: zoom,
          child: child,
        ),
      ),
    );
  }
}

@Preview(name: 'Slide canvas viewport', size: Size(760, 460))
Widget slideCanvasViewportPreview() {
  return ProviderScope(
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SlideCanvasViewport(
          child: Container(
            width: 960,
            height: 540,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
