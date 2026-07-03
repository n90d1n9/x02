import 'document_navigation_panel_switcher.dart';

/// Describes the active left-side navigation rail for the document workspace.
class DocumentWorkspaceNavigationState {
  final DocumentNavigationPanelMode? activeMode;

  const DocumentWorkspaceNavigationState._(this.activeMode);

  /// Creates a closed navigation rail state.
  const DocumentWorkspaceNavigationState.closed() : this._(null);

  /// Creates a navigation rail state focused on page thumbnails.
  const DocumentWorkspaceNavigationState.pages()
    : this._(DocumentNavigationPanelMode.pages);

  /// Creates a navigation rail state focused on the document outline.
  const DocumentWorkspaceNavigationState.outline()
    : this._(DocumentNavigationPanelMode.outline);

  /// Builds a state from legacy visibility flags while keeping pages dominant.
  factory DocumentWorkspaceNavigationState.fromVisibility({
    required bool showOutline,
    required bool showPageNavigator,
  }) {
    if (showPageNavigator) {
      return const DocumentWorkspaceNavigationState.pages();
    }
    if (showOutline) {
      return const DocumentWorkspaceNavigationState.outline();
    }
    return const DocumentWorkspaceNavigationState.closed();
  }

  bool get isOpen => activeMode != null;

  bool get showsPages => activeMode == DocumentNavigationPanelMode.pages;

  bool get showsOutline => activeMode == DocumentNavigationPanelMode.outline;

  double get railWidth {
    return switch (activeMode) {
      DocumentNavigationPanelMode.pages => 284,
      DocumentNavigationPanelMode.outline => 260,
      null => 0,
    };
  }

  DocumentWorkspaceNavigationState open(DocumentNavigationPanelMode mode) {
    return switch (mode) {
      DocumentNavigationPanelMode.pages =>
        const DocumentWorkspaceNavigationState.pages(),
      DocumentNavigationPanelMode.outline =>
        const DocumentWorkspaceNavigationState.outline(),
    };
  }

  DocumentWorkspaceNavigationState toggle(DocumentNavigationPanelMode mode) {
    if (activeMode == mode) {
      return const DocumentWorkspaceNavigationState.closed();
    }
    return open(mode);
  }

  DocumentWorkspaceNavigationState close() {
    return const DocumentWorkspaceNavigationState.closed();
  }
}
