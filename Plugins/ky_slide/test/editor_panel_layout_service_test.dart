import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/services/editor_panel_layout_service.dart';

void main() {
  test('editor panel layout keeps both panels when canvas budget allows', () {
    final layout = EditorPanelLayoutService.resolve(
      availableWidth: 1200,
      slideNavigatorVisible: true,
      propertiesPanelVisible: true,
    );

    expect(layout.showSlideNavigator, isTrue);
    expect(layout.showPropertiesPanel, isTrue);
    expect(layout.slideNavigatorWidth, 240);
    expect(layout.propertiesPanelWidth, 288);
    expect(layout.reservedWidth, 528);
  });

  test('editor panel layout prioritizes slide navigation on medium widths', () {
    final layout = EditorPanelLayoutService.resolve(
      availableWidth: 980,
      slideNavigatorVisible: true,
      propertiesPanelVisible: true,
    );

    expect(layout.showSlideNavigator, isTrue);
    expect(layout.showPropertiesPanel, isFalse);
  });

  test('editor panel layout shows inspector when navigator is hidden', () {
    final layout = EditorPanelLayoutService.resolve(
      availableWidth: 860,
      slideNavigatorVisible: false,
      propertiesPanelVisible: true,
    );

    expect(layout.showSlideNavigator, isFalse);
    expect(layout.showPropertiesPanel, isTrue);
  });

  test('editor panel layout protects canvas on narrow widths', () {
    final layout = EditorPanelLayoutService.resolve(
      availableWidth: 700,
      slideNavigatorVisible: true,
      propertiesPanelVisible: true,
    );

    expect(layout.showSlideNavigator, isFalse);
    expect(layout.showPropertiesPanel, isFalse);
  });
}
