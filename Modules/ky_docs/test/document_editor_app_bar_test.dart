import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/document_editing_mode.dart';
import 'package:ky_docs/docx/models/document_metadata.dart';
import 'package:ky_docs/docx/models/document_state.dart';
import 'package:ky_docs/docx/models/page_layout.dart';
import 'package:ky_docs/docx/widgets/document_editor_app_bar.dart';
import 'package:ky_docs/docx/widgets/editor_app_bar/document_action_cluster.dart';
import 'package:ky_docs/docx/widgets/editor_app_bar/document_title.dart';
import 'package:ky_docs/docx/widgets/review_mode/document_editing_mode_switcher.dart';
import 'package:ky_docs/docx/widgets/review_hub/document_side_panel.dart';

void main() {
  group('DocumentEditorAppBar', () {
    void useViewport(WidgetTester tester, Size size) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }

    testWidgets('exposes the review hub as one editor action', (tester) async {
      useViewport(tester, const Size(1200, 700));
      DocumentSidePanel? selectedPanel;

      await _pumpAppBar(
        tester,
        onToggleSidePanel: (panel) => selectedPanel = panel,
      );

      await tester.tap(find.byTooltip('Review Hub'));

      expect(selectedPanel, DocumentSidePanel.review);
    });

    testWidgets('exposes sharing as a first-class editor action', (
      tester,
    ) async {
      useViewport(tester, const Size(1200, 700));
      var openedCollaboration = false;

      await _pumpAppBar(
        tester,
        onOpenCollaboration: () => openedCollaboration = true,
      );

      await tester.tap(find.byTooltip('Share'));

      expect(openedCollaboration, isTrue);
    });

    testWidgets('exposes the command palette action', (tester) async {
      useViewport(tester, const Size(1200, 700));
      var openedPalette = false;

      await _pumpAppBar(
        tester,
        onOpenCommandPalette: () => openedPalette = true,
      );

      await tester.tap(find.byTooltip('Command palette'));

      expect(openedPalette, isTrue);
    });

    testWidgets('routes page navigator from the expanded view menu', (
      tester,
    ) async {
      useViewport(tester, const Size(1500, 700));
      var toggledPageNavigator = false;

      await _pumpAppBar(
        tester,
        onTogglePageNavigator: () => toggledPageNavigator = true,
      );

      await tester.tap(find.byTooltip('View'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Page Navigator'));
      await tester.pumpAndSettle();

      expect(toggledPageNavigator, isTrue);
    });

    testWidgets('groups expanded actions into command clusters', (
      tester,
    ) async {
      useViewport(tester, const Size(1500, 700));

      await _pumpAppBar(
        tester,
        showFindReplace: true,
        showAIAssistant: true,
        showInsertMenu: true,
      );

      for (final groupId in [
        'mode',
        'review',
        'create',
        'collaboration',
        'proofing',
        'file',
      ]) {
        expect(
          find.byKey(DocumentActionCluster.groupKey(groupId)),
          findsOneWidget,
        );
      }

      final findButton = tester
          .widgetList<IconButton>(find.byType(IconButton))
          .singleWhere((button) => button.tooltip == 'Find & Replace');
      expect(findButton.isSelected, isTrue);
    });

    testWidgets('routes editing mode changes on roomy layouts', (tester) async {
      useViewport(tester, const Size(1500, 700));
      DocumentEditingMode? selectedMode;

      await _pumpAppBar(
        tester,
        onEditingModeChanged: (mode) => selectedMode = mode,
      );

      await tester.tap(find.byKey(DocumentEditingModeSwitcher.buttonKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Suggesting'));
      await tester.pumpAndSettle();

      expect(selectedMode, DocumentEditingMode.suggesting);
    });

    testWidgets('locks mutating actions in viewing mode', (tester) async {
      useViewport(tester, const Size(1500, 700));
      var editedTitle = false;
      var toggledFavorite = false;
      var openedAi = false;
      var openedInsert = false;
      String? importedFormat;

      await _pumpAppBar(
        tester,
        editingMode: DocumentEditingMode.viewing,
        onEditTitle: () => editedTitle = true,
        onToggleFavorite: () => toggledFavorite = true,
        onToggleAIAssistant: () => openedAi = true,
        onToggleInsertMenu: () => openedInsert = true,
        onImport: (format) => importedFormat = format,
      );

      expect(find.byIcon(Icons.lock_outline), findsOneWidget);

      await tester.tap(
        find.byKey(DocumentEditorTitle.titleKey),
        warnIfMissed: false,
      );
      await tester.tap(find.byIcon(Icons.star_outline), warnIfMissed: false);
      await tester.tap(
        find.byIcon(Icons.psychology_outlined),
        warnIfMissed: false,
      );
      await tester.tap(
        find.byIcon(Icons.add_box_outlined),
        warnIfMissed: false,
      );
      await tester.tap(find.byIcon(Icons.file_upload), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(editedTitle, isFalse);
      expect(toggledFavorite, isFalse);
      expect(openedAi, isFalse);
      expect(openedInsert, isFalse);
      expect(importedFormat, isNull);
    });

    testWidgets('routes the review hub from compact overflow', (tester) async {
      useViewport(tester, const Size(760, 700));
      DocumentSidePanel? selectedPanel;

      await _pumpAppBar(
        tester,
        onToggleSidePanel: (panel) => selectedPanel = panel,
      );

      expect(find.byTooltip('Review Hub'), findsNothing);
      expect(find.byTooltip('Document actions'), findsOneWidget);

      await tester.tap(find.byTooltip('Document actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Review Hub'));
      await tester.pumpAndSettle();

      expect(selectedPanel, DocumentSidePanel.review);
    });
  });
}

Future<void> _pumpAppBar(
  WidgetTester tester, {
  DocumentSidePanel? activeSidePanel,
  DocumentEditingMode editingMode = DocumentEditingMode.editing,
  bool showFindReplace = false,
  bool showAIAssistant = false,
  bool showInsertMenu = false,
  VoidCallback? onEditTitle,
  VoidCallback? onToggleFavorite,
  ValueChanged<DocumentSidePanel>? onToggleSidePanel,
  ValueChanged<DocumentEditingMode>? onEditingModeChanged,
  VoidCallback? onToggleAIAssistant,
  VoidCallback? onToggleInsertMenu,
  VoidCallback? onTogglePageNavigator,
  ValueChanged<String>? onImport,
  VoidCallback? onOpenCommandPalette,
  VoidCallback? onOpenCollaboration,
}) {
  final controller = quill.QuillController.basic();
  addTearDown(controller.dispose);

  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        appBar: DocumentEditorAppBar(
          documentState: DocumentState(
            controller: controller,
            metadata: DocumentMetadata(
              id: 'doc-1',
              title: 'Proposal',
              createdAt: DateTime(2026),
              modifiedAt: DateTime(2026, 1, 2),
            ),
          ),
          showStatistics: false,
          showFindReplace: showFindReplace,
          showAIAssistant: showAIAssistant,
          showInsertMenu: showInsertMenu,
          showOutline: false,
          showPageNavigator: false,
          activeSidePanel: activeSidePanel,
          editingMode: editingMode,
          onEditTitle: onEditTitle ?? () {},
          onToggleFavorite: onToggleFavorite ?? () {},
          onToggleStatistics: () {},
          onToggleFindReplace: () {},
          onToggleAIAssistant: onToggleAIAssistant ?? () {},
          onToggleInsertMenu: onToggleInsertMenu ?? () {},
          onToggleOutline: () {},
          onTogglePageNavigator: onTogglePageNavigator ?? () {},
          onToggleSidePanel: onToggleSidePanel ?? (_) {},
          onEditingModeChanged: onEditingModeChanged ?? (_) {},
          onToggleSpellCheck: () {},
          onSave: () async {},
          onImport: onImport ?? (_) {},
          onExport: (_) {},
          onSetPageLayout: (PageLayout _) {},
          onOpenCommandPalette: onOpenCommandPalette ?? () {},
          onOpenCollaboration: onOpenCollaboration ?? () {},
          onMoreOptions: () {},
        ),
      ),
    ),
  );
}
