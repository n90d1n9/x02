import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widget_previews.dart';

import '../../states/component_provider.dart';
import '../../states/presentation_provider.dart';
import 'slide_canvas.dart';
import 'slide_canvas_viewport.dart';
import 'slide_canvas_workspace.dart';

/// Provider adapter that connects the active presentation to canvas workspace UI.
class SlideCanvasArea extends ConsumerWidget {
  const SlideCanvasArea({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showRuler = ref.watch(rulerVisibilityProvider);
    final cursorPosition = ref.watch(cursorPositionProvider);
    final presentation = ref.watch(presentationProvider);

    return SlideCanvasWorkspace(
      showRuler: showRuler,
      slideSize: presentation.slideSize,
      cursorPosition: cursorPosition,
      child: const SlideCanvasViewport(child: SlideCanvas()),
    );
  }
}

@Preview(name: 'Slide canvas area', size: Size(820, 520))
Widget slideCanvasAreaPreview() {
  return const ProviderScope(
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF101114),
        body: SlideCanvasArea(),
      ),
    ),
  );
}
