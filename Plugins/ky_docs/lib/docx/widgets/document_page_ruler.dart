import 'package:flutter/material.dart';

import '../models/page_settings.dart';
import 'ruler/document_page_ruler_geometry.dart';

/// Displays a Word-style horizontal ruler with page ticks and margin handles.
class DocumentPageRuler extends StatefulWidget {
  static const rulerKey = ValueKey('document-page-ruler');
  static const leftMarginHandleKey = ValueKey(
    'document-page-ruler-left-margin',
  );
  static const rightMarginHandleKey = ValueKey(
    'document-page-ruler-right-margin',
  );

  final PageSettings pageSettings;
  final double height;
  final ValueChanged<EdgeInsets>? onMarginsChanged;

  const DocumentPageRuler({
    super.key,
    required this.pageSettings,
    this.height = 28,
    this.onMarginsChanged,
  });

  @override
  State<DocumentPageRuler> createState() => _DocumentPageRulerState();
}

/// Coordinates ruler drag gestures with point-based page margin updates.
class _DocumentPageRulerState extends State<DocumentPageRuler> {
  EdgeInsets? _dragStartMargins;
  double _dragDeltaPixels = 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pageWidth = widget.pageSettings.getPageSize().width;

    return Semantics(
      container: true,
      label: _semanticLabel(pageWidth),
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final surfaceWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : pageWidth;
            final geometry = DocumentPageRulerGeometry(
              pageWidth: pageWidth,
              surfaceWidth: surfaceWidth,
              leftMargin: widget.pageSettings.margins.left,
              rightMargin: widget.pageSettings.margins.right,
            );

            return SizedBox(
              key: DocumentPageRuler.rulerKey,
              height: widget.height,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: [
                  CustomPaint(
                    painter: _DocumentPageRulerPainter(
                      geometry: geometry,
                      colorScheme: colorScheme,
                    ),
                  ),
                  _MarginHandle(
                    handleKey: DocumentPageRuler.leftMarginHandleKey,
                    x: geometry.leftMarginX,
                    surfaceWidth: surfaceWidth,
                    enabled: widget.onMarginsChanged != null,
                    tooltip:
                        'Left margin ${widget.pageSettings.margins.left.round()} pt',
                    onDragStart: _beginMarginDrag,
                    onDragUpdate: (details) {
                      _updateMarginDrag(
                        handle: _MarginDragHandle.left,
                        geometry: geometry,
                        details: details,
                      );
                    },
                    onDragEnd: (_) => _finishMarginDrag(),
                    onDragCancel: _finishMarginDrag,
                  ),
                  _MarginHandle(
                    handleKey: DocumentPageRuler.rightMarginHandleKey,
                    x: geometry.rightMarginX,
                    surfaceWidth: surfaceWidth,
                    enabled: widget.onMarginsChanged != null,
                    tooltip:
                        'Right margin ${widget.pageSettings.margins.right.round()} pt',
                    onDragStart: _beginMarginDrag,
                    onDragUpdate: (details) {
                      _updateMarginDrag(
                        handle: _MarginDragHandle.right,
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

  String _semanticLabel(double pageWidth) {
    final writingWidth =
        pageWidth -
        widget.pageSettings.margins.left -
        widget.pageSettings.margins.right;
    return 'Page ruler, left margin ${widget.pageSettings.margins.left.round()} points, '
        'right margin ${widget.pageSettings.margins.right.round()} points, '
        'writing width ${writingWidth.round()} points';
  }

  void _beginMarginDrag(DragStartDetails details) {
    if (widget.onMarginsChanged == null) return;

    _dragStartMargins = widget.pageSettings.margins;
    _dragDeltaPixels = 0;
  }

  void _updateMarginDrag({
    required _MarginDragHandle handle,
    required DocumentPageRulerGeometry geometry,
    required DragUpdateDetails details,
  }) {
    final onMarginsChanged = widget.onMarginsChanged;
    if (onMarginsChanged == null) return;

    _dragStartMargins ??= widget.pageSettings.margins;
    _dragDeltaPixels += details.primaryDelta ?? details.delta.dx;

    final startMargins = _dragStartMargins!;
    final deltaPoints = geometry.pointsForPixels(_dragDeltaPixels);
    final nextMargins = switch (handle) {
      _MarginDragHandle.left => geometry.moveLeftMargin(
        margins: startMargins,
        deltaPoints: deltaPoints,
      ),
      _MarginDragHandle.right => geometry.moveRightMargin(
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

/// Identifies which page margin handle is currently being dragged.
enum _MarginDragHandle { left, right }

/// Shows a compact visual marker for a page margin position.
class _MarginHandle extends StatelessWidget {
  static const _width = 18.0;

  final Key handleKey;
  final double x;
  final double surfaceWidth;
  final bool enabled;
  final String tooltip;
  final GestureDragStartCallback onDragStart;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;
  final GestureDragCancelCallback onDragCancel;

  const _MarginHandle({
    required this.handleKey,
    required this.x,
    required this.surfaceWidth,
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
    final maxLeft = surfaceWidth <= _width ? 0.0 : surfaceWidth - _width;
    final left = (x - (_width / 2)).clamp(0.0, maxLeft).toDouble();

    return Positioned(
      top: 1,
      left: left,
      width: _width,
      child: MouseRegion(
        cursor: enabled
            ? SystemMouseCursors.resizeLeftRight
            : SystemMouseCursors.basic,
        child: GestureDetector(
          key: handleKey,
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: enabled ? onDragStart : null,
          onHorizontalDragUpdate: enabled ? onDragUpdate : null,
          onHorizontalDragEnd: enabled ? onDragEnd : null,
          onHorizontalDragCancel: enabled ? onDragCancel : null,
          child: Tooltip(
            message: enabled ? tooltip : '$tooltip - locked',
            child: Opacity(
              opacity: enabled ? 1 : 0.62,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const SizedBox(width: 12, height: 4),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the ruler background, tick marks, shaded margins, and margin lines.
class _DocumentPageRulerPainter extends CustomPainter {
  final DocumentPageRulerGeometry geometry;
  final ColorScheme colorScheme;

  const _DocumentPageRulerPainter({
    required this.geometry,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = colorScheme.surfaceContainerHighest.withValues(alpha: 0.62);
    final marginPaint = Paint()
      ..color = colorScheme.primaryContainer.withValues(alpha: 0.34);
    final tickPaint = Paint()
      ..color = colorScheme.onSurfaceVariant.withValues(alpha: 0.62)
      ..strokeWidth = 1;
    final marginLinePaint = Paint()
      ..color = colorScheme.primary.withValues(alpha: 0.82)
      ..strokeWidth = 1.4;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(6)),
      backgroundPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, geometry.leftMarginX, size.height),
      marginPaint,
    );
    canvas.drawRect(
      Rect.fromLTRB(geometry.rightMarginX, 0, size.width, size.height),
      marginPaint,
    );

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (final tick in geometry.ticks()) {
      final tickHeight = _tickHeight(tick.kind);

      canvas.drawLine(
        Offset(tick.x, size.height),
        Offset(tick.x, size.height - tickHeight),
        tickPaint,
      );

      if (tick.kind == DocumentPageRulerTickKind.inch && tick.inchNumber > 0) {
        textPainter.text = TextSpan(
          text: '${tick.inchNumber}',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.82),
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(tick.x - textPainter.width / 2, 3));
      }
    }

    canvas.drawLine(
      Offset(geometry.leftMarginX, 0),
      Offset(geometry.leftMarginX, size.height),
      marginLinePaint,
    );
    canvas.drawLine(
      Offset(geometry.rightMarginX, 0),
      Offset(geometry.rightMarginX, size.height),
      marginLinePaint,
    );
  }

  double _tickHeight(DocumentPageRulerTickKind kind) {
    return switch (kind) {
      DocumentPageRulerTickKind.inch => 18,
      DocumentPageRulerTickKind.halfInch => 13,
      DocumentPageRulerTickKind.quarterInch => 9,
      DocumentPageRulerTickKind.eighthInch => 5,
    };
  }

  @override
  bool shouldRepaint(covariant _DocumentPageRulerPainter oldDelegate) {
    return geometry != oldDelegate.geometry ||
        colorScheme != oldDelegate.colorScheme;
  }
}
