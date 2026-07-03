/// Resolved side-panel visibility and sizing for the presentation editor.
class EditorPanelLayout {
  final bool showSlideNavigator;
  final bool showPropertiesPanel;
  final double slideNavigatorWidth;
  final double propertiesPanelWidth;

  const EditorPanelLayout({
    required this.showSlideNavigator,
    required this.showPropertiesPanel,
    required this.slideNavigatorWidth,
    required this.propertiesPanelWidth,
  });

  double get reservedWidth {
    return (showSlideNavigator ? slideNavigatorWidth : 0) +
        (showPropertiesPanel ? propertiesPanelWidth : 0);
  }
}
