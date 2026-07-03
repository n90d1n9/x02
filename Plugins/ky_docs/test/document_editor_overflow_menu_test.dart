import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/document_editor_action_policy.dart';
import 'package:ky_docs/docx/models/document_editing_mode.dart';
import 'package:ky_docs/docx/models/page_layout.dart';
import 'package:ky_docs/docx/widgets/editor_app_bar/overflow_menu.dart';
import 'package:ky_docs/docx/widgets/review_hub/document_side_panel.dart';

void main() {
  group('DocumentEditorOverflowMenu', () {
    testWidgets('routes secondary toolbar actions from a compact menu', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      DocumentSidePanel? selectedPanel;
      DocumentEditingMode? selectedMode;
      String? exportedFormat;
      PageLayout? selectedLayout;
      var toggledPageNavigator = false;

      await _pumpMenu(
        tester,
        onToggleSidePanel: (panel) => selectedPanel = panel,
        onEditingModeChanged: (mode) => selectedMode = mode,
        onExport: (format) => exportedFormat = format,
        onSetPageLayout: (layout) => selectedLayout = layout,
        onTogglePageNavigator: () => toggledPageNavigator = true,
      );

      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Review Hub'));
      await tester.pumpAndSettle();

      expect(selectedPanel, DocumentSidePanel.review);

      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Suggesting mode'));
      await tester.pumpAndSettle();

      expect(selectedMode, DocumentEditingMode.suggesting);

      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Export PDF (Advanced)'));
      await tester.pumpAndSettle();

      expect(exportedFormat, 'pdf_advanced');

      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Web Layout'));
      await tester.pumpAndSettle();

      expect(selectedLayout, PageLayout.web);

      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Page Navigator'));
      await tester.pumpAndSettle();

      expect(toggledPageNavigator, isTrue);
    });

    testWidgets('keeps save disabled when there are no changes', (
      tester,
    ) async {
      var saved = false;

      await _pumpMenu(tester, canSave: false, onSave: () async => saved = true);

      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'), warnIfMissed: false);

      expect(saved, isFalse);
    });

    testWidgets('locks mutating compact actions in viewing mode', (
      tester,
    ) async {
      var openedAi = false;
      var openedInsert = false;
      String? importedFormat;

      await _pumpMenu(
        tester,
        editingMode: DocumentEditingMode.viewing,
        onToggleAIAssistant: () => openedAi = true,
        onToggleInsertMenu: () => openedInsert = true,
        onImport: (format) => importedFormat = format,
      );

      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();

      expect(find.text('AI Assistant'), findsOneWidget);
      expect(find.text('Insert'), findsOneWidget);
      expect(find.text('Import DOCX'), findsOneWidget);

      await tester.tap(find.text('AI Assistant'), warnIfMissed: false);
      await tester.tap(find.text('Insert'), warnIfMissed: false);
      await tester.tap(find.text('Import DOCX'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(openedAi, isFalse);
      expect(openedInsert, isFalse);
      expect(importedFormat, isNull);
    });
  });
}

Future<void> _pumpMenu(
  WidgetTester tester, {
  bool canSave = true,
  DocumentEditingMode editingMode = DocumentEditingMode.editing,
  Future<void> Function()? onSave,
  ValueChanged<DocumentSidePanel>? onToggleSidePanel,
  ValueChanged<DocumentEditingMode>? onEditingModeChanged,
  VoidCallback? onToggleAIAssistant,
  VoidCallback? onToggleInsertMenu,
  VoidCallback? onTogglePageNavigator,
  ValueChanged<String>? onImport,
  ValueChanged<String>? onExport,
  ValueChanged<PageLayout>? onSetPageLayout,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: DocumentEditorOverflowMenu(
            showStatistics: false,
            showFindReplace: false,
            showAIAssistant: false,
            showInsertMenu: false,
            showOutline: false,
            showPageNavigator: false,
            activeSidePanel: null,
            editingMode: editingMode,
            actionPolicy: DocumentEditorActionPolicy(editingMode: editingMode),
            spellCheckEnabled: false,
            canSave: canSave,
            currentLayout: PageLayout.print,
            onToggleStatistics: () {},
            onToggleFindReplace: () {},
            onToggleAIAssistant: onToggleAIAssistant ?? () {},
            onToggleInsertMenu: onToggleInsertMenu ?? () {},
            onToggleOutline: () {},
            onTogglePageNavigator: onTogglePageNavigator ?? () {},
            onToggleSidePanel: onToggleSidePanel ?? (_) {},
            onEditingModeChanged: onEditingModeChanged ?? (_) {},
            onToggleSpellCheck: () {},
            onSave: onSave ?? () async {},
            onImport: onImport ?? (_) {},
            onExport: onExport ?? (_) {},
            onSetPageLayout: onSetPageLayout ?? (_) {},
            onMoreOptions: () {},
          ),
        ),
      ),
    ),
  );
}
