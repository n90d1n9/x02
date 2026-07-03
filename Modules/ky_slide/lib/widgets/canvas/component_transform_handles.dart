import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/enums.dart';

/// Reusable selected-object resize handle with tooltip, semantics, and cursor.
class ComponentResizeHandle extends StatelessWidget {
  final ResizeHandle handle;
  final Alignment alignment;
  final GestureDragStartCallback? onPanStart;
  final GestureDragUpdateCallback? onPanUpdate;
  final GestureDragEndCallback? onPanEnd;

  const ComponentResizeHandle({
    super.key,
    required this.handle,
    required this.alignment,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
  });

  @override
  Widget build(BuildContext context) {
    final tooltip = resizeHandleTooltip(handle);

    return Align(
      alignment: alignment,
      child: GestureDetector(
        onPanStart: onPanStart,
        onPanUpdate: onPanUpdate,
        onPanEnd: onPanEnd,
        child: Semantics(
          button: true,
          label: tooltip,
          child: Tooltip(
            message: tooltip,
            child: MouseRegion(
              cursor: resizeHandleCursor(handle),
              child: Container(
                key: ValueKey('resize-handle-${handle.name}'),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Reusable selected-object rotate handle with a small connector stem.
class ComponentRotateHandle extends StatelessWidget {
  final double componentWidth;
  final GestureDragStartCallback? onPanStart;
  final GestureDragUpdateCallback? onPanUpdate;
  final GestureDragEndCallback? onPanEnd;

  const ComponentRotateHandle({
    super.key,
    required this.componentWidth,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -40,
      left: componentWidth / 2 - 15,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onPanStart: onPanStart,
            onPanUpdate: onPanUpdate,
            onPanEnd: onPanEnd,
            child: Semantics(
              button: true,
              label: 'Rotate object',
              child: Tooltip(
                message: 'Rotate object',
                child: MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: Container(
                    key: const ValueKey('rotate-handle'),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF14B8A6), Color(0xFF6366F1)],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.rotate_right,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            key: const ValueKey('rotate-handle-connector'),
            width: 2,
            height: 10,
            decoration: BoxDecoration(
              color: const Color(0xFF14B8A6).withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tooltip copy for resize handles, shared by the editor and tests.
String resizeHandleTooltip(ResizeHandle handle) {
  return switch (handle) {
    ResizeHandle.topLeft => 'Resize from top left',
    ResizeHandle.topRight => 'Resize from top right',
    ResizeHandle.bottomLeft => 'Resize from bottom left',
    ResizeHandle.bottomRight => 'Resize from bottom right',
    ResizeHandle.top => 'Resize from top',
    ResizeHandle.bottom => 'Resize from bottom',
    ResizeHandle.left => 'Resize from left',
    ResizeHandle.right => 'Resize from right',
    ResizeHandle.rotate => 'Rotate object',
  };
}

/// Desktop cursor used by each resize handle orientation.
MouseCursor resizeHandleCursor(ResizeHandle handle) {
  return switch (handle) {
    ResizeHandle.topLeft ||
    ResizeHandle.bottomRight => SystemMouseCursors.resizeUpLeftDownRight,
    ResizeHandle.topRight ||
    ResizeHandle.bottomLeft => SystemMouseCursors.resizeUpRightDownLeft,
    ResizeHandle.top || ResizeHandle.bottom => SystemMouseCursors.resizeUpDown,
    ResizeHandle.left ||
    ResizeHandle.right => SystemMouseCursors.resizeLeftRight,
    ResizeHandle.rotate => SystemMouseCursors.click,
  };
}

@Preview(name: 'Component resize handle', size: Size(180, 120))
Widget componentResizeHandlePreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF101114),
      body: Center(
        child: Container(
          width: 110,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF1D4ED8).withValues(alpha: 0.32),
            border: Border.all(color: const Color(0xFF6366F1), width: 2),
          ),
          child: const Stack(
            children: [
              ComponentResizeHandle(
                handle: ResizeHandle.right,
                alignment: Alignment.centerRight,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

@Preview(name: 'Component rotate handle', size: Size(180, 140))
Widget componentRotateHandlePreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF101114),
      body: Center(
        child: Container(
          width: 110,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF1D4ED8).withValues(alpha: 0.32),
            border: Border.all(color: const Color(0xFF6366F1), width: 2),
          ),
          child: const Stack(
            clipBehavior: Clip.none,
            children: [ComponentRotateHandle(componentWidth: 110)],
          ),
        ),
      ),
    ),
  );
}
