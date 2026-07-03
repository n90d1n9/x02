import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../services/editor_panel_layout_service.dart';
import 'editor_compact_panel_dock.dart';
import 'editor_compact_panel_sheet.dart';
import 'editor_side_panel_frame.dart';

/// Responsive workspace scaffold for editor chrome, side panels, canvas, and status surfaces.
class EditorWorkspaceShell extends StatelessWidget {
  final bool showSlideNavigator;
  final bool showPropertiesPanel;
  final bool showSpeakerNotes;
  final Widget slideNavigator;
  final Widget toolbar;
  final Widget canvasArea;
  final Widget speakerNotes;
  final Widget statusBar;
  final Widget propertiesPanel;

  const EditorWorkspaceShell({
    super.key,
    required this.showSlideNavigator,
    required this.showPropertiesPanel,
    required this.showSpeakerNotes,
    required this.slideNavigator,
    required this.toolbar,
    required this.canvasArea,
    required this.speakerNotes,
    required this.statusBar,
    required this.propertiesPanel,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = EditorPanelLayoutService.resolve(
          availableWidth: constraints.maxWidth,
          slideNavigatorVisible: showSlideNavigator,
          propertiesPanelVisible: showPropertiesPanel,
        );
        final hiddenSlideNavigator =
            showSlideNavigator && !layout.showSlideNavigator;
        final hiddenPropertiesPanel =
            showPropertiesPanel && !layout.showPropertiesPanel;

        return Stack(
          children: [
            Positioned.fill(
              child: Row(
                children: [
                  if (layout.showSlideNavigator)
                    EditorSidePanelFrame(
                      width: layout.slideNavigatorWidth,
                      side: EditorSidePanelSide.left,
                      child: slideNavigator,
                    ),
                  Expanded(
                    child: Column(
                      children: [
                        toolbar,
                        Expanded(
                          child: Column(
                            children: [
                              Expanded(child: canvasArea),
                              if (showSpeakerNotes) speakerNotes,
                              statusBar,
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (layout.showPropertiesPanel)
                    EditorSidePanelFrame(
                      width: layout.propertiesPanelWidth,
                      side: EditorSidePanelSide.right,
                      child: propertiesPanel,
                    ),
                ],
              ),
            ),
            if (hiddenSlideNavigator || hiddenPropertiesPanel)
              Positioned(
                top: 72,
                right: 16,
                child: EditorCompactPanelDock(
                  accentColor: const Color(0xFF38BDF8),
                  items: [
                    if (hiddenSlideNavigator)
                      EditorCompactPanelDockItem(
                        icon: Icons.view_carousel_outlined,
                        tooltip: 'Open slide navigator panel',
                        onPressed: () => _showCompactPanel(
                          context,
                          title: 'Slide navigator',
                          icon: Icons.view_carousel_outlined,
                          child: slideNavigator,
                        ),
                      ),
                    if (hiddenPropertiesPanel)
                      EditorCompactPanelDockItem(
                        icon: Icons.tune,
                        tooltip: 'Open inspector panel',
                        onPressed: () => _showCompactPanel(
                          context,
                          title: 'Inspector',
                          icon: Icons.tune,
                          child: propertiesPanel,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  void _showCompactPanel(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.86,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: EditorCompactPanelSheet(
                title: title,
                icon: icon,
                onClose: () => Navigator.of(sheetContext).pop(),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

@Preview(name: 'Editor workspace shell', size: Size(1100, 620))
Widget editorWorkspaceShellPreview() {
  return const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: EditorWorkspaceShell(
        showSlideNavigator: true,
        showPropertiesPanel: true,
        showSpeakerNotes: true,
        slideNavigator: _WorkspaceShellPreviewPanel(label: 'Slides'),
        toolbar: _WorkspaceShellPreviewBar(label: 'Ribbon'),
        canvasArea: _WorkspaceShellPreviewCanvas(),
        speakerNotes: _WorkspaceShellPreviewBar(label: 'Speaker notes'),
        statusBar: _WorkspaceShellPreviewBar(label: 'Status'),
        propertiesPanel: _WorkspaceShellPreviewPanel(label: 'Inspector'),
      ),
    ),
  );
}

/// Compact placeholder panel used by widget previews for the editor workspace shell.
class _WorkspaceShellPreviewPanel extends StatelessWidget {
  final String label;

  const _WorkspaceShellPreviewPanel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Compact placeholder bar used by widget previews for editor chrome strips.
class _WorkspaceShellPreviewBar extends StatelessWidget {
  final String label;

  const _WorkspaceShellPreviewBar({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Compact placeholder canvas used by widget previews for the editor workspace shell.
class _WorkspaceShellPreviewCanvas extends StatelessWidget {
  const _WorkspaceShellPreviewCanvas();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: const Center(
            child: Text(
              'Slide canvas',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
