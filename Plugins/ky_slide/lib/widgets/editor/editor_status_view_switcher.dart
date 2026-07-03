import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'editor_status_bar_widgets.dart';

/// View destinations exposed by the compact editor status-bar switcher.
enum EditorStatusViewMode { edit, slideBoard, present }

extension EditorStatusViewModeDetails on EditorStatusViewMode {
  String get label {
    return switch (this) {
      EditorStatusViewMode.edit => 'Editing',
      EditorStatusViewMode.slideBoard => 'Slide board',
      EditorStatusViewMode.present => 'Presenting',
    };
  }

  IconData get icon {
    return switch (this) {
      EditorStatusViewMode.edit => Icons.edit_note,
      EditorStatusViewMode.slideBoard => Icons.grid_view,
      EditorStatusViewMode.present => Icons.play_arrow_rounded,
    };
  }

  Color get accentColor {
    return switch (this) {
      EditorStatusViewMode.edit => const Color(0xFF38BDF8),
      EditorStatusViewMode.slideBoard => const Color(0xFFA78BFA),
      EditorStatusViewMode.present => const Color(0xFF34D399),
    };
  }
}

/// Compact status-bar shortcuts for normal editing, slide board, and presenting.
class EditorStatusViewSwitcher extends StatelessWidget {
  final EditorStatusViewMode activeMode;
  final bool showActiveLabel;
  final VoidCallback onEditSelected;
  final VoidCallback onSlideBoardSelected;
  final VoidCallback onPresentSelected;

  const EditorStatusViewSwitcher({
    super.key,
    required this.activeMode,
    this.showActiveLabel = true,
    required this.onEditSelected,
    required this.onSlideBoardSelected,
    required this.onPresentSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showActiveLabel) ...[
          EditorStatusViewModePill(activeMode: activeMode),
          const SizedBox(width: 4),
        ],
        _EditorStatusViewButton(
          tooltip: 'Normal editing view',
          icon: EditorStatusViewMode.edit.icon,
          isActive: activeMode == EditorStatusViewMode.edit,
          activeColor: EditorStatusViewMode.edit.accentColor,
          onPressed: onEditSelected,
        ),
        _EditorStatusViewButton(
          tooltip: 'Open slide board',
          icon: EditorStatusViewMode.slideBoard.icon,
          isActive: activeMode == EditorStatusViewMode.slideBoard,
          activeColor: EditorStatusViewMode.slideBoard.accentColor,
          onPressed: onSlideBoardSelected,
        ),
        _EditorStatusViewButton(
          tooltip: 'Start presenter view',
          icon: EditorStatusViewMode.present.icon,
          isActive: activeMode == EditorStatusViewMode.present,
          activeColor: EditorStatusViewMode.present.accentColor,
          onPressed: onPresentSelected,
        ),
      ],
    );
  }
}

/// Compact status-bar chip that names the currently active editor view.
class EditorStatusViewModePill extends StatelessWidget {
  final EditorStatusViewMode activeMode;

  const EditorStatusViewModePill({super.key, required this.activeMode});

  @override
  Widget build(BuildContext context) {
    final accentColor = activeMode.accentColor;

    return Tooltip(
      message: 'Active view: ${activeMode.label}',
      child: Semantics(
        label: 'Active editor view',
        value: activeMode.label,
        child: Container(
          width: 96,
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: accentColor.withValues(alpha: 0.24)),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.3),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  activeMode.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Icon button used by the status-bar view switcher.
class _EditorStatusViewButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onPressed;

  const _EditorStatusViewButton({
    required this.tooltip,
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : Colors.white38;

    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon, size: 16),
      color: color,
      hoverColor: color.withValues(alpha: 0.12),
      highlightColor: color.withValues(alpha: 0.14),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
      style: IconButton.styleFrom(
        backgroundColor: isActive
            ? activeColor.withValues(alpha: 0.12)
            : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      ),
      onPressed: onPressed,
    );
  }
}

@Preview(name: 'Editor status view switcher', size: Size(280, 80))
Widget editorStatusViewSwitcherPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: EditorStatusControlGroup(
          children: [
            EditorStatusViewSwitcher(
              activeMode: EditorStatusViewMode.slideBoard,
              onEditSelected: () {},
              onSlideBoardSelected: () {},
              onPresentSelected: () {},
            ),
          ],
        ),
      ),
    ),
  );
}

@Preview(name: 'Editor status view mode pill', size: Size(180, 80))
Widget editorStatusViewModePillPreview() {
  return const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: Center(
        child: EditorStatusViewModePill(
          activeMode: EditorStatusViewMode.present,
        ),
      ),
    ),
  );
}
