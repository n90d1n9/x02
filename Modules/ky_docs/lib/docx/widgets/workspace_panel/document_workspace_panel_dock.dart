import 'package:flutter/material.dart';

import 'document_workspace_panel_id.dart';
import 'document_workspace_panel_width_menu.dart';
import 'document_workspace_panel_width_preset.dart';

/// Provides the responsive dock surface for editor utility panels.
class DocumentWorkspacePanelDock extends StatelessWidget {
  static const dockKey = ValueKey('document-workspace-panel-dock');
  static const switcherKey = ValueKey('document-workspace-panel-switcher');
  static const closeButtonKey = ValueKey('document-workspace-panel-close');
  static const contentKey = ValueKey('document-workspace-panel-dock-content');
  static const resizeHandleKey = ValueKey(
    'document-workspace-panel-resize-handle',
  );
  static const minSideWidth = DocumentWorkspacePanelWidthScale.compact;
  static const defaultSideWidth = DocumentWorkspacePanelWidthScale.comfortable;
  static const sideWidth = defaultSideWidth;
  static const maxSideWidth = DocumentWorkspacePanelWidthScale.expanded;
  static const stackedHeight = 360.0;

  final DocumentWorkspacePanelId activePanel;
  final bool sideBySide;
  final double currentSideWidth;
  final List<DocumentWorkspacePanelDockOption> panels;
  final ValueChanged<DocumentWorkspacePanelId>? onPanelSelected;
  final ValueChanged<double>? onSideWidthChanged;
  final VoidCallback? onClose;
  final Widget child;

  const DocumentWorkspacePanelDock({
    super.key,
    required this.activePanel,
    required this.sideBySide,
    this.currentSideWidth = defaultSideWidth,
    this.panels = const [],
    this.onPanelSelected,
    this.onSideWidthChanged,
    this.onClose,
    required this.child,
  });

  static Key panelButtonKey(DocumentWorkspacePanelId id) {
    return ValueKey('document-workspace-panel-switch-${id.name}');
  }

  static double clampSideWidth(double width) {
    return DocumentWorkspacePanelWidthScale.clamp(width);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final showResizeHandle = sideBySide && onSideWidthChanged != null;
    final content = Column(
      children: [
        if (panels.isNotEmpty) ...[
          _DockPanelSwitcher(
            activePanel: activePanel,
            currentSideWidth: clampSideWidth(currentSideWidth),
            panels: panels,
            onPanelSelected: onPanelSelected,
            onSideWidthChanged: showResizeHandle ? onSideWidthChanged : null,
            onClose: onClose,
          ),
          Divider(height: 1, color: colorScheme.outlineVariant),
        ],
        Expanded(
          child: ClipRect(
            child: SingleChildScrollView(
              key: contentKey,
              padding: EdgeInsets.zero,
              child: child,
            ),
          ),
        ),
      ],
    );

    return Semantics(
      container: true,
      label: activePanel.label,
      child: DecoratedBox(
        key: dockKey,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          border: sideBySide
              ? Border(
                  left: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.7),
                  ),
                )
              : Border(
                  bottom: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.7),
                  ),
                ),
        ),
        child: SizedBox.expand(
          child: showResizeHandle
              ? Stack(
                  children: [
                    Positioned.fill(child: content),
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: _DockResizeHandle(
                        width: clampSideWidth(currentSideWidth),
                        onWidthChanged: onSideWidthChanged!,
                      ),
                    ),
                  ],
                )
              : content,
        ),
      ),
    );
  }
}

/// Describes one selectable utility panel in the workspace dock switcher.
class DocumentWorkspacePanelDockOption {
  final DocumentWorkspacePanelId id;
  final bool enabled;
  final String? disabledTooltip;

  const DocumentWorkspacePanelDockOption({
    required this.id,
    this.enabled = true,
    this.disabledTooltip,
  });
}

/// Renders the compact utility-panel switcher at the top of the dock.
class _DockPanelSwitcher extends StatelessWidget {
  final DocumentWorkspacePanelId activePanel;
  final double currentSideWidth;
  final List<DocumentWorkspacePanelDockOption> panels;
  final ValueChanged<DocumentWorkspacePanelId>? onPanelSelected;
  final ValueChanged<double>? onSideWidthChanged;
  final VoidCallback? onClose;

  const _DockPanelSwitcher({
    required this.activePanel,
    required this.currentSideWidth,
    required this.panels,
    required this.onPanelSelected,
    required this.onSideWidthChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      key: DocumentWorkspacePanelDock.switcherKey,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(activePanel.icon, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  activePanel.label,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (onSideWidthChanged != null)
                DocumentWorkspacePanelWidthMenu(
                  currentWidth: currentSideWidth,
                  onWidthChanged: onSideWidthChanged!,
                ),
              if (onClose != null)
                IconButton(
                  key: DocumentWorkspacePanelDock.closeButtonKey,
                  tooltip: 'Close ${activePanel.label}',
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    minimumSize: const Size.square(34),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: onClose,
                ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final option in panels) ...[
                  _DockPanelButton(
                    option: option,
                    active: option.id == activePanel,
                    onPressed: option.enabled && onPanelSelected != null
                        ? () => onPanelSelected?.call(option.id)
                        : null,
                  ),
                  if (option != panels.last) const SizedBox(width: 4),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Draws one icon-only panel switcher action with a stable size.
class _DockPanelButton extends StatelessWidget {
  final DocumentWorkspacePanelDockOption option;
  final bool active;
  final VoidCallback? onPressed;

  const _DockPanelButton({
    required this.option,
    required this.active,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tooltip = option.enabled
        ? option.id.label
        : option.disabledTooltip ?? option.id.label;

    return IconButton(
      key: DocumentWorkspacePanelDock.panelButtonKey(option.id),
      isSelected: active,
      tooltip: tooltip,
      selectedIcon: Icon(option.id.icon),
      icon: Icon(option.id.icon),
      style: ButtonStyle(
        minimumSize: WidgetStateProperty.all(const Size.square(36)),
        padding: WidgetStateProperty.all(EdgeInsets.zero),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (!active || states.contains(WidgetState.disabled)) return null;
          return colorScheme.primaryContainer.withValues(alpha: 0.88);
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return colorScheme.onSurface.withValues(alpha: 0.38);
          }
          if (active) return colorScheme.onPrimaryContainer;
          return colorScheme.onSurfaceVariant;
        }),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      onPressed: onPressed,
    );
  }
}

/// Provides a precise drag affordance for resizing the side utility dock.
class _DockResizeHandle extends StatefulWidget {
  final double width;
  final ValueChanged<double> onWidthChanged;

  const _DockResizeHandle({required this.width, required this.onWidthChanged});

  @override
  State<_DockResizeHandle> createState() => _DockResizeHandleState();
}

/// Tracks resize gesture state so drag deltas accumulate predictably.
class _DockResizeHandleState extends State<_DockResizeHandle> {
  var _hovered = false;
  var _dragging = false;
  var _dragStartWidth = DocumentWorkspacePanelDock.defaultSideWidth;
  var _dragDelta = 0.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final handleColor = _dragging
        ? colorScheme.primary
        : _hovered
        ? colorScheme.primary.withValues(alpha: 0.7)
        : colorScheme.outlineVariant.withValues(alpha: 0.72);

    return Semantics(
      label: 'Resize workspace panel',
      hint: 'Drag left or right to resize the utility panel',
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeLeftRight,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          key: DocumentWorkspacePanelDock.resizeHandleKey,
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: _handleDragStart,
          onHorizontalDragUpdate: _handleDragUpdate,
          onHorizontalDragEnd: (_) => _handleDragEnd(),
          onHorizontalDragCancel: _handleDragEnd,
          child: SizedBox(
            width: 12,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOutCubic,
                width: _dragging || _hovered ? 4 : 2,
                height: _dragging || _hovered ? 88 : 54,
                decoration: BoxDecoration(
                  color: handleColor,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleDragStart(DragStartDetails details) {
    setState(() {
      _dragging = true;
      _dragStartWidth = DocumentWorkspacePanelDock.clampSideWidth(widget.width);
      _dragDelta = 0;
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _dragDelta += details.delta.dx;
    final nextWidth = DocumentWorkspacePanelDock.clampSideWidth(
      _dragStartWidth - _dragDelta,
    );
    widget.onWidthChanged(nextWidth);
  }

  void _handleDragEnd() {
    if (!_dragging) return;
    setState(() => _dragging = false);
  }
}
