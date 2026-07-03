import 'package:flutter/material.dart';

import '../model/workbook_sheet.dart';
import '../theme/ky_sheet_theme.dart';

/// Drag-and-drop wrapper that reorders workbook sheet tabs.
class SheetTabReorderTarget extends StatefulWidget {
  const SheetTabReorderTarget({
    super.key,
    required this.sheet,
    required this.active,
    required this.enabled,
    required this.onDropped,
    required this.child,
  });

  /// Sheet represented by the tab inside this reorder target.
  final WorkbookSheet sheet;

  /// Whether this target wraps the active workbook sheet.
  final bool active;

  /// Whether drag-and-drop reordering is available for this tab.
  final bool enabled;

  /// Called with the dragged sheet id and intended insertion edge.
  final SheetTabReorderDropCallback onDropped;

  /// Rendered sheet tab.
  final Widget child;

  @override
  State<SheetTabReorderTarget> createState() => _SheetTabReorderTargetState();
}

/// Called when a sheet tab is dropped before or after a target tab.
typedef SheetTabReorderDropCallback =
    void Function(String draggedSheetId, SheetTabReorderEdge edge);

/// Insertion edge selected while hovering over a target sheet tab.
enum SheetTabReorderEdge { before, after }

/// Tracks sheet tab hover position and renders insertion feedback.
class _SheetTabReorderTargetState extends State<SheetTabReorderTarget> {
  SheetTabReorderEdge? _hoverEdge;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => details.data != widget.sheet.id,
      onMove: (details) => _setHoverEdge(_edgeForOffset(details.offset)),
      onLeave: (_) => _setHoverEdge(null),
      onAcceptWithDetails: (details) {
        final edge = _hoverEdge ?? _edgeForOffset(details.offset);
        _setHoverEdge(null);
        widget.onDropped(details.data, edge);
      },
      builder: (context, candidateData, rejectedData) {
        final highlighted = candidateData.isNotEmpty;
        final edge = _hoverEdge ?? SheetTabReorderEdge.after;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Draggable<String>(
              data: widget.sheet.id,
              axis: Axis.horizontal,
              dragAnchorStrategy: pointerDragAnchorStrategy,
              feedback: _SheetTabDragFeedback(
                sheet: widget.sheet,
                active: widget.active,
              ),
              childWhenDragging: Opacity(opacity: 0.48, child: widget.child),
              child: widget.child,
            ),
            _SheetTabDropIndicator(visible: highlighted, edge: edge),
          ],
        );
      },
    );
  }

  SheetTabReorderEdge _edgeForOffset(Offset globalOffset) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return SheetTabReorderEdge.after;

    final localOffset = box.globalToLocal(globalOffset);
    return localOffset.dx < box.size.width / 2
        ? SheetTabReorderEdge.before
        : SheetTabReorderEdge.after;
  }

  void _setHoverEdge(SheetTabReorderEdge? edge) {
    if (_hoverEdge == edge) return;
    setState(() {
      _hoverEdge = edge;
    });
  }
}

/// Vertical insertion marker shown beside the hovered drop edge.
class _SheetTabDropIndicator extends StatelessWidget {
  const _SheetTabDropIndicator({required this.visible, required this.edge});

  final bool visible;
  final SheetTabReorderEdge edge;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 5,
      bottom: 5,
      left: edge == SheetTabReorderEdge.before ? -1 : null,
      right: edge == SheetTabReorderEdge.after ? 5 : null,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutCubic,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: KySheetColors.accent,
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x330256B3),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const SizedBox(width: 3),
          ),
        ),
      ),
    );
  }
}

/// Floating visual representation of a sheet tab while it is being dragged.
class _SheetTabDragFeedback extends StatelessWidget {
  const _SheetTabDragFeedback({required this.sheet, required this.active});

  final WorkbookSheet sheet;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final tabColor = sheet.tabColor;
    final baseBackground = active
        ? KySheetColors.accentSoft
        : KySheetColors.surface;
    final backgroundColor = tabColor == null
        ? baseBackground
        : Color.alphaBlend(tabColor.withAlpha(34), baseBackground);

    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tabColor ?? KySheetColors.accent),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 104, maxWidth: 180),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.table_chart_outlined,
                  size: 16,
                  color: active
                      ? KySheetColors.accent
                      : KySheetColors.mutedText,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    sheet.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: active ? KySheetColors.accent : KySheetColors.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
