import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/navigation/document_navigation_panel_switcher.dart';
import 'package:ky_docs/docx/widgets/navigation/document_workspace_navigation_state.dart';

void main() {
  group('DocumentWorkspaceNavigationState', () {
    test('opens, toggles, and closes mutually exclusive navigation modes', () {
      const closed = DocumentWorkspaceNavigationState.closed();

      final pages = closed.open(DocumentNavigationPanelMode.pages);
      final outline = pages.open(DocumentNavigationPanelMode.outline);

      expect(closed.isOpen, isFalse);
      expect(pages.showsPages, isTrue);
      expect(pages.showsOutline, isFalse);
      expect(outline.showsPages, isFalse);
      expect(outline.showsOutline, isTrue);
      expect(
        outline.toggle(DocumentNavigationPanelMode.outline).isOpen,
        isFalse,
      );
      expect(outline.close().isOpen, isFalse);
    });

    test('builds from visibility flags with page navigator priority', () {
      final state = DocumentWorkspaceNavigationState.fromVisibility(
        showOutline: true,
        showPageNavigator: true,
      );

      expect(state.showsPages, isTrue);
      expect(state.showsOutline, isFalse);
      expect(state.railWidth, 284);
    });
  });
}
