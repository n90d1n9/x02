import 'package:flutter/material.dart';

/// Identifies the available left navigation rail panels in the document editor.
enum DocumentNavigationPanelMode { pages, outline }

/// Provides labels and iconography for document navigation rail modes.
extension DocumentNavigationPanelModeDetails on DocumentNavigationPanelMode {
  String get label {
    return switch (this) {
      DocumentNavigationPanelMode.pages => 'Pages',
      DocumentNavigationPanelMode.outline => 'Outline',
    };
  }

  IconData get icon {
    return switch (this) {
      DocumentNavigationPanelMode.pages => Icons.view_agenda_outlined,
      DocumentNavigationPanelMode.outline => Icons.account_tree_outlined,
    };
  }
}

/// Switches between page thumbnails and document outline navigation panels.
class DocumentNavigationPanelSwitcher extends StatelessWidget {
  static Key modeButtonKey(DocumentNavigationPanelMode mode) {
    return Key('document-navigation-panel-switcher-${mode.name}');
  }

  final DocumentNavigationPanelMode selectedMode;
  final VoidCallback? onPagesSelected;
  final VoidCallback? onOutlineSelected;
  final Key? pagesButtonKey;
  final Key? outlineButtonKey;

  const DocumentNavigationPanelSwitcher({
    super.key,
    required this.selectedMode,
    this.onPagesSelected,
    this.onOutlineSelected,
    this.pagesButtonKey,
    this.outlineButtonKey,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.72),
        ),
      ),
      child: Row(
        children: [
          for (final mode in DocumentNavigationPanelMode.values)
            Expanded(
              child: _NavigationPanelModeButton(
                key: _keyFor(mode),
                mode: mode,
                selected: selectedMode == mode,
                onPressed: _callbackFor(mode),
              ),
            ),
        ],
      ),
    );
  }

  Key _keyFor(DocumentNavigationPanelMode mode) {
    return switch (mode) {
      DocumentNavigationPanelMode.pages =>
        pagesButtonKey ?? modeButtonKey(mode),
      DocumentNavigationPanelMode.outline =>
        outlineButtonKey ?? modeButtonKey(mode),
    };
  }

  VoidCallback? _callbackFor(DocumentNavigationPanelMode mode) {
    if (selectedMode == mode) return null;
    return switch (mode) {
      DocumentNavigationPanelMode.pages => onPagesSelected,
      DocumentNavigationPanelMode.outline => onOutlineSelected,
    };
  }
}

/// Renders one selectable mode inside the navigation rail switcher.
class _NavigationPanelModeButton extends StatelessWidget {
  final DocumentNavigationPanelMode mode;
  final bool selected;
  final VoidCallback? onPressed;

  const _NavigationPanelModeButton({
    super.key,
    required this.mode,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = selected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: '${mode.label} navigation',
      child: Material(
        color: selected
            ? colorScheme.primaryContainer.withValues(alpha: 0.86)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(mode.icon, size: 16, color: foreground),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    mode.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: foreground,
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
