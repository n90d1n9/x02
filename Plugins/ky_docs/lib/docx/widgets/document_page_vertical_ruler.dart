import 'package:flutter/material.dart';

import '../models/page_settings.dart';
import 'ruler/document_page_vertical_ruler_geometry.dart';
import 'ruler/document_page_vertical_ruler_painter.dart';

/// Displays a vertical print-layout ruler for top and bottom page margins.
class DocumentPageVerticalRuler extends StatefulWidget {
  static const rulerKey = ValueKey('document-page-vertical-ruler');
  static const topMarginHandleKey = ValueKey(
    'document-page-vertical-ruler-top-margin',
  );
  static const bottomMarginHandleKey = ValueKey(
    'document-page-vertical-ruler-bottom-margin',
  );

  final PageSettings pageSettings;
  final double width;
  final ValueChanged<EdgeInsets>? onMarginsChanged;

  const DocumentPageVerticalRuler({
    super.key,
    required this.pageSettings,
    this.width = 28,
    this.onMarginsChanged,
  });

  @override
  State<DocumentPageVerticalRuler> createState() =>
      _DocumentPageVerticalRulerState();
}

/// Coordinates vertical ruler drag gestures with page margin updates.
class _DocumentPageVerticalRulerState extends State<DocumentPageVerticalRuler> {
  EdgeInsets? _dragStartMargins;
  double _dragDeltaPixels = 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pageHeight = widget.pageSettings.getPageSize().height;

    return Semantics(
      container: true,
      label: _semanticLabel(pageHeight),
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final surfaceHeight = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : pageHeight;
            final geometry = DocumentPageVerticalRulerGeometry(
              pageHeight: pageHeight,
              surfaceHeight: surfaceHeight,
              topMargin: widget.pageSettings.margins.top,
              bottomMargin: widget.pageSettings.margins.bottom,
            );

            return SizedBox(
              key: DocumentPageVerticalRuler.rulerKey,
              width: widget.width,
              height: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: [
                  CustomPaint(
                    painter: DocumentPageVerticalRulerPainter(
                      geometry: geometry,
                      colorScheme: colorScheme,
                    ),
                  ),
                  _VerticalMarginHandle(
                    handleKey: DocumentPageVerticalRuler.topMarginHandleKey,
                    y: geometry.topMarginY,
                    surfaceHeight: surfaceHeight,
                    enabled: widget.onMarginsChanged != null,
                    tooltip:
                        'Top margin ${widget.pageSettings.margins.top.round()} pt',
                    onDragStart: _beginMarginDrag,
                    onDragUpdate: (details) {
                      _updateMarginDrag(
                        handle: _VerticalMarginDragHandle.top,
                        geometry: geometry,
                        details: details,
                      );
                    },
                    onDragEnd: (_) => _finishMarginDrag(),
                    onDragCancel: _finishMarginDrag,
                  ),
                  _VerticalMarginHandle(
                    handleKey: DocumentPageVerticalRuler.bottomMarginHandleKey,
                    y: geometry.bottomMarginY,
                    surfaceHeight: surfaceHeight,
                    enabled: widget.onMarginsChanged != null,
                    tooltip:
                        'Bottom margin ${widget.pageSettings.margins.bottom.round()} pt',
                    onDragStart: _beginMarginDrag,
                    onDragUpdate: (details) {
                      _updateMarginDrag(
                        handle: _VerticalMarginDragHandle.bottom,
                        geometry: geometry,
                        details: details,
                      );
                    },
                    onDragEnd: (_) => _finishMarginDrag(),
                    onDragCancel: _finishMarginDrag,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _semanticLabel(double pageHeight) {
    final writingHeight =
        pageHeight -
        widget.pageSettings.margins.top -
        widget.pageSettings.margins.bottom;
    return 'Vertical page ruler, top margin ${widget.pageSettings.margins.top.round()} points, '
        'bottom margin ${widget.pageSettings.margins.bottom.round()} points, '
        'writing height ${writingHeight.round()} points';
  }

  void _beginMarginDrag(DragStartDetails details) {
    if (widget.onMarginsChanged == null) return;

    _dragStartMargins = widget.pageSettings.margins;
    _dragDeltaPixels = 0;
  }

  void _updateMarginDrag({
    required _VerticalMarginDragHandle handle,
    required DocumentPageVerticalRulerGeometry geometry,
    required DragUpdateDetails details,
  }) {
    final onMarginsChanged = widget.onMarginsChanged;
    if (onMarginsChanged == null) return;

    _dragStartMargins ??= widget.pageSettings.margins;
    _dragDeltaPixels += details.primaryDelta ?? details.delta.dy;

    final startMargins = _dragStartMargins!;
    final deltaPoints = geometry.pointsForPixels(_dragDeltaPixels);
    final nextMargins = switch (handle) {
      _VerticalMarginDragHandle.top => geometry.moveTopMargin(
        margins: startMargins,
        deltaPoints: deltaPoints,
      ),
      _VerticalMarginDragHandle.bottom => geometry.moveBottomMargin(
        margins: startMargins,
        deltaPoints: deltaPoints,
      ),
    };

    onMarginsChanged(nextMargins);
  }

  void _finishMarginDrag() {
    _dragStartMargins = null;
    _dragDeltaPixels = 0;
  }
}

/// Identifies which vertical page margin handle is being dragged.
enum _VerticalMarginDragHandle { top, bottom }

/// Shows a compact draggable marker for a vertical margin position.
class _VerticalMarginHandle extends StatelessWidget {
  static const _height = 18.0;

  final Key handleKey;
  final double y;
  final double surfaceHeight;
  final bool enabled;
  final String tooltip;
  final GestureDragStartCallback onDragStart;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;
  final GestureDragCancelCallback onDragCancel;

  const _VerticalMarginHandle({
    required this.handleKey,
    required this.y,
    required this.surfaceHeight,
    required this.enabled,
    required this.tooltip,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDragCancel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxTop = surfaceHeight <= _height ? 0.0 : surfaceHeight - _height;
    final top = (y - (_height / 2)).clamp(0.0, maxTop).toDouble();

    return Positioned(
      top: top,
      left: 1,
      right: 1,
      height: _height,
      child: MouseRegion(
        cursor: enabled
            ? SystemMouseCursors.resizeUpDown
            : SystemMouseCursors.basic,
        child: GestureDetector(
          key: handleKey,
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: enabled ? onDragStart : null,
          onVerticalDragUpdate: enabled ? onDragUpdate : null,
          onVerticalDragEnd: enabled ? onDragEnd : null,
          onVerticalDragCancel: enabled ? onDragCancel : null,
          child: Tooltip(
            message: enabled ? tooltip : '$tooltip - locked',
            child: Opacity(
              opacity: enabled ? 1 : 0.62,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const SizedBox(width: 4, height: 12),
                  ),
                  Icon(Icons.arrow_right, size: 16, color: colorScheme.primary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
