import '../models/editor_panel_layout.dart';

/// Calculates responsive editor side-panel visibility without coupling it to UI widgets.
class EditorPanelLayoutService {
  static const double minCanvasWidth = 520;
  static const double compactSlideNavigatorWidth = 240;
  static const double roomySlideNavigatorWidth = 264;
  static const double compactPropertiesPanelWidth = 288;
  static const double roomyPropertiesPanelWidth = 336;
  static const double roomyBreakpoint = 1360;

  const EditorPanelLayoutService._();

  static EditorPanelLayout resolve({
    required double availableWidth,
    required bool slideNavigatorVisible,
    required bool propertiesPanelVisible,
  }) {
    if (!availableWidth.isFinite || availableWidth <= 0) {
      return const EditorPanelLayout(
        showSlideNavigator: false,
        showPropertiesPanel: false,
        slideNavigatorWidth: compactSlideNavigatorWidth,
        propertiesPanelWidth: compactPropertiesPanelWidth,
      );
    }

    final slideNavigatorWidth = availableWidth >= roomyBreakpoint
        ? roomySlideNavigatorWidth
        : compactSlideNavigatorWidth;
    final propertiesPanelWidth = availableWidth >= roomyBreakpoint
        ? roomyPropertiesPanelWidth
        : compactPropertiesPanelWidth;

    var showSlideNavigator =
        slideNavigatorVisible &&
        availableWidth - slideNavigatorWidth >= minCanvasWidth;
    var showPropertiesPanel =
        propertiesPanelVisible &&
        availableWidth - propertiesPanelWidth >= minCanvasWidth;

    final canvasWidthWithBoth =
        availableWidth - slideNavigatorWidth - propertiesPanelWidth;
    if (showSlideNavigator &&
        showPropertiesPanel &&
        canvasWidthWithBoth < minCanvasWidth) {
      showPropertiesPanel = false;
    }

    return EditorPanelLayout(
      showSlideNavigator: showSlideNavigator,
      showPropertiesPanel: showPropertiesPanel,
      slideNavigatorWidth: slideNavigatorWidth,
      propertiesPanelWidth: propertiesPanelWidth,
    );
  }
}
