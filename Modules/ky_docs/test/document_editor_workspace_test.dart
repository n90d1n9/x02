import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/document_editing_mode.dart';
import 'package:ky_docs/docx/models/document_metadata.dart';
import 'package:ky_docs/docx/models/document_state.dart';
import 'package:ky_docs/docx/services/document_statistics.dart';
import 'package:ky_docs/docx/widgets/document_editor_workspace.dart';
import 'package:ky_docs/docx/widgets/document_formatting_toolbar.dart';
import 'package:ky_docs/docx/widgets/navigation/document_workspace_navigation_state.dart';
import 'package:ky_docs/docx/widgets/outline/outline_panel.dart';
import 'package:ky_docs/docx/widgets/page_navigation/document_page_navigator_panel.dart';
import 'package:ky_docs/docx/widgets/review_hub/document_side_panel.dart';
import 'package:ky_docs/docx/widgets/review_mode/document_editing_mode_banner.dart';
import 'package:ky_docs/docx/widgets/workspace_activity/document_workspace_activity_bar.dart';
import 'package:ky_docs/docx/widgets/workspace_activity/document_workspace_activity_item.dart';
import 'package:ky_docs/docx/widgets/workspace_panel/document_workspace_panel_dock.dart';
import 'package:ky_docs/docx/widgets/workspace_panel/document_workspace_panel_id.dart';
import 'package:ky_docs/docx/widgets/workspace_panel/document_workspace_panel_width_menu.dart';
import 'package:ky_docs/docx/widgets/workspace_panel/document_workspace_panel_width_preset.dart';

void main() {
  group('DocumentEditorWorkspace', () {
    void useViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(1200, 820);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }

    testWidgets('locks the editor surface in viewing mode', (tester) async {
      useViewport(tester);
      final controller = _controllerWithText('Viewing mode document.');
      addTearDown(controller.dispose);
      DocumentEditingMode? selectedMode;

      await _pumpWorkspace(
        tester,
        controller: controller,
        editingMode: DocumentEditingMode.viewing,
        onEditingModeChanged: (mode) => selectedMode = mode,
      );

      expect(controller.readOnly, isTrue);
      expect(find.byKey(DocumentFormattingToolbar.toolbarKey), findsNothing);
      expect(find.byKey(DocumentEditingModeBanner.bannerKey), findsOneWidget);

      await tester.tap(find.byKey(DocumentEditingModeBanner.primaryActionKey));

      expect(selectedMode, DocumentEditingMode.editing);
    });

    testWidgets('keeps editing tools available in suggesting mode', (
      tester,
    ) async {
      useViewport(tester);
      final controller = _controllerWithText('Suggesting mode document.');
      addTearDown(controller.dispose);
      DocumentSidePanel? selectedPanel;

      await _pumpWorkspace(
        tester,
        controller: controller,
        editingMode: DocumentEditingMode.suggesting,
        onSidePanelChanged: (panel) => selectedPanel = panel,
      );

      expect(controller.readOnly, isFalse);
      expect(find.byKey(DocumentFormattingToolbar.toolbarKey), findsOneWidget);

      await tester.tap(find.byKey(DocumentEditingModeBanner.primaryActionKey));

      expect(selectedPanel, DocumentSidePanel.trackChanges);
    });

    testWidgets('shows the page navigator and opens outline from its rail', (
      tester,
    ) async {
      useViewport(tester);
      final controller = _controllerWithText('Page navigator document.');
      addTearDown(controller.dispose);
      var openedOutline = false;

      await _pumpWorkspace(
        tester,
        controller: controller,
        editingMode: DocumentEditingMode.editing,
        showPageNavigator: true,
        onOpenOutline: () => openedOutline = true,
      );

      expect(find.byKey(DocumentPageNavigatorPanel.panelKey), findsOneWidget);
      expect(
        find.byKey(DocumentPageNavigatorPanel.pageTileKey(1)),
        findsOneWidget,
      );

      await tester.tap(find.byKey(DocumentPageNavigatorPanel.outlineButtonKey));

      expect(openedOutline, isTrue);
    });

    testWidgets('renders the active navigation state as a single rail', (
      tester,
    ) async {
      useViewport(tester);
      final controller = _controllerWithText('# Navigation state document');
      addTearDown(controller.dispose);

      await _pumpWorkspace(
        tester,
        controller: controller,
        editingMode: DocumentEditingMode.editing,
        navigationState: const DocumentWorkspaceNavigationState.pages(),
      );

      expect(find.byKey(DocumentPageNavigatorPanel.panelKey), findsOneWidget);
      expect(find.text('Document map'), findsNothing);

      await _pumpWorkspace(
        tester,
        controller: controller,
        editingMode: DocumentEditingMode.editing,
        navigationState: const DocumentWorkspaceNavigationState.outline(),
      );

      expect(find.byKey(DocumentPageNavigatorPanel.panelKey), findsNothing);
      expect(find.text('Document map'), findsOneWidget);
    });

    testWidgets('closes the page navigator rail from its header', (
      tester,
    ) async {
      useViewport(tester);
      final controller = _controllerWithText('Page navigator document.');
      addTearDown(controller.dispose);
      var closedNavigation = false;

      await _pumpWorkspace(
        tester,
        controller: controller,
        editingMode: DocumentEditingMode.editing,
        showPageNavigator: true,
        onCloseNavigationPanel: () => closedNavigation = true,
      );

      await tester.tap(find.byKey(DocumentPageNavigatorPanel.closeButtonKey));

      expect(closedNavigation, isTrue);
    });

    testWidgets('shows outline and opens pages from its rail', (tester) async {
      useViewport(tester);
      final controller = _controllerWithText('# Outline document');
      addTearDown(controller.dispose);
      var openedPages = false;

      await _pumpWorkspace(
        tester,
        controller: controller,
        editingMode: DocumentEditingMode.editing,
        showOutline: true,
        onOpenPageNavigator: () => openedPages = true,
      );

      expect(find.text('Document map'), findsOneWidget);

      await tester.tap(find.byKey(DocxOutlinePanel.pagesButtonKey));

      expect(openedPages, isTrue);
    });

    testWidgets('closes the outline rail from its header', (tester) async {
      useViewport(tester);
      final controller = _controllerWithText('# Outline document');
      addTearDown(controller.dispose);
      var closedNavigation = false;

      await _pumpWorkspace(
        tester,
        controller: controller,
        editingMode: DocumentEditingMode.editing,
        showOutline: true,
        onCloseNavigationPanel: () => closedNavigation = true,
      );

      await tester.tap(find.byKey(DocxOutlinePanel.closeButtonKey));

      expect(closedNavigation, isTrue);
    });

    testWidgets('routes workspace activity rail shortcuts', (tester) async {
      useViewport(tester);
      final controller = _controllerWithText('Activity rail document.');
      addTearDown(controller.dispose);
      var toggledOutline = false;
      var toggledPages = false;
      var openedReview = false;
      var toggledStatistics = false;
      var toggledFindReplace = false;
      var toggledAi = false;
      var toggledInsert = false;

      await _pumpWorkspace(
        tester,
        controller: controller,
        editingMode: DocumentEditingMode.editing,
        onToggleOutline: () => toggledOutline = true,
        onTogglePageNavigator: () => toggledPages = true,
        onSidePanelChanged: (panel) {
          openedReview = panel == DocumentSidePanel.review;
        },
        onToggleStatistics: () => toggledStatistics = true,
        onToggleFindReplace: () => toggledFindReplace = true,
        onToggleAIAssistant: () => toggledAi = true,
        onToggleInsertMenu: () => toggledInsert = true,
      );

      expect(find.byKey(DocumentWorkspaceActivityBar.barKey), findsOneWidget);

      await tester.tap(_activityFinder(DocumentWorkspaceActivityId.outline));
      await tester.tap(_activityFinder(DocumentWorkspaceActivityId.pages));
      await tester.tap(_activityFinder(DocumentWorkspaceActivityId.review));
      await tester.tap(_activityFinder(DocumentWorkspaceActivityId.statistics));
      await tester.tap(
        _activityFinder(DocumentWorkspaceActivityId.findReplace),
      );
      await tester.tap(
        _activityFinder(DocumentWorkspaceActivityId.aiAssistant),
      );
      await tester.tap(_activityFinder(DocumentWorkspaceActivityId.insert));

      expect(toggledOutline, isTrue);
      expect(toggledPages, isTrue);
      expect(openedReview, isTrue);
      expect(toggledStatistics, isTrue);
      expect(toggledFindReplace, isTrue);
      expect(toggledAi, isTrue);
      expect(toggledInsert, isTrue);
    });

    testWidgets('locks mutating activity shortcuts in viewing mode', (
      tester,
    ) async {
      useViewport(tester);
      final controller = _controllerWithText('Locked activity rail document.');
      addTearDown(controller.dispose);
      var toggledAi = false;
      var toggledInsert = false;

      await _pumpWorkspace(
        tester,
        controller: controller,
        editingMode: DocumentEditingMode.viewing,
        onToggleAIAssistant: () => toggledAi = true,
        onToggleInsertMenu: () => toggledInsert = true,
      );

      final aiButton = tester.widget<IconButton>(
        _activityFinder(DocumentWorkspaceActivityId.aiAssistant),
      );
      final insertButton = tester.widget<IconButton>(
        _activityFinder(DocumentWorkspaceActivityId.insert),
      );

      expect(aiButton.onPressed, isNull);
      expect(insertButton.onPressed, isNull);

      await tester.tap(
        _activityFinder(DocumentWorkspaceActivityId.aiAssistant),
        warnIfMissed: false,
      );
      await tester.tap(
        _activityFinder(DocumentWorkspaceActivityId.insert),
        warnIfMissed: false,
      );

      expect(toggledAi, isFalse);
      expect(toggledInsert, isFalse);
    });

    testWidgets('hides the workspace activity rail on compact layouts', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(720, 820);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final controller = _controllerWithText('Compact rail document.');
      addTearDown(controller.dispose);

      await _pumpWorkspace(
        tester,
        controller: controller,
        editingMode: DocumentEditingMode.editing,
        width: 720,
      );

      expect(find.byKey(DocumentWorkspaceActivityBar.barKey), findsNothing);
    });

    testWidgets('renders the active utility panel in a side dock', (
      tester,
    ) async {
      useViewport(tester);
      final controller = _controllerWithText('Docked panel document.');
      addTearDown(controller.dispose);
      var closedDock = false;

      await _pumpWorkspace(
        tester,
        controller: controller,
        editingMode: DocumentEditingMode.editing,
        activeWorkspacePanel: DocumentWorkspacePanelId.statistics,
        workspacePanel: const Text('Docked statistics content'),
        onCloseWorkspacePanel: () => closedDock = true,
      );

      expect(find.byKey(DocumentWorkspacePanelDock.dockKey), findsOneWidget);
      expect(find.text('Writing statistics'), findsOneWidget);
      expect(find.text('Docked statistics content'), findsOneWidget);

      final dockSize = tester.getSize(
        find.byKey(DocumentWorkspacePanelDock.dockKey),
      );
      expect(dockSize.width, DocumentWorkspacePanelDock.sideWidth);

      final statisticsButton = tester.widget<IconButton>(
        _activityFinder(DocumentWorkspaceActivityId.statistics),
      );
      expect(statisticsButton.isSelected, isTrue);
      expect(
        find.byKey(DocumentWorkspacePanelDock.switcherKey),
        findsOneWidget,
      );
      expect(
        tester
            .widget<IconButton>(
              find.byKey(
                DocumentWorkspacePanelDock.panelButtonKey(
                  DocumentWorkspacePanelId.statistics,
                ),
              ),
            )
            .isSelected,
        isTrue,
      );

      await tester.tap(find.byKey(DocumentWorkspacePanelDock.closeButtonKey));

      expect(closedDock, isTrue);
    });

    testWidgets('uses the requested utility side dock width', (tester) async {
      useViewport(tester);
      final controller = _controllerWithText('Custom dock width document.');
      addTearDown(controller.dispose);

      await _pumpWorkspace(
        tester,
        controller: controller,
        editingMode: DocumentEditingMode.editing,
        activeWorkspacePanel: DocumentWorkspacePanelId.statistics,
        workspacePanel: const Text('Wider statistics content'),
        workspacePanelWidth: 420,
      );

      final dockSize = tester.getSize(
        find.byKey(DocumentWorkspacePanelDock.dockKey),
      );
      expect(dockSize.width, 420);
    });

    testWidgets('routes side dock resize updates', (tester) async {
      useViewport(tester);
      final controller = _controllerWithText('Resizable dock document.');
      addTearDown(controller.dispose);
      double? resizedWidth;

      await _pumpWorkspace(
        tester,
        controller: controller,
        editingMode: DocumentEditingMode.editing,
        activeWorkspacePanel: DocumentWorkspacePanelId.findReplace,
        workspacePanel: const Text('Resizable find content'),
        workspacePanelWidth: 390,
        onWorkspacePanelWidthChanged: (width) => resizedWidth = width,
      );

      expect(
        find.byKey(DocumentWorkspacePanelDock.resizeHandleKey),
        findsOneWidget,
      );

      await tester.drag(
        find.byKey(DocumentWorkspacePanelDock.resizeHandleKey),
        const Offset(-48, 0),
      );

      expect(resizedWidth, closeTo(438, 0.1));
    });

    testWidgets('clamps side dock resize updates', (tester) async {
      useViewport(tester);
      final controller = _controllerWithText('Clamped dock document.');
      addTearDown(controller.dispose);
      double? resizedWidth;

      await _pumpWorkspace(
        tester,
        controller: controller,
        editingMode: DocumentEditingMode.editing,
        activeWorkspacePanel: DocumentWorkspacePanelId.findReplace,
        workspacePanel: const Text('Clamped find content'),
        workspacePanelWidth: 390,
        onWorkspacePanelWidthChanged: (width) => resizedWidth = width,
      );

      await tester.drag(
        find.byKey(DocumentWorkspacePanelDock.resizeHandleKey),
        const Offset(-220, 0),
      );

      expect(resizedWidth, DocumentWorkspacePanelDock.maxSideWidth);
    });

    testWidgets('snaps side dock width from preset menu', (tester) async {
      useViewport(tester);
      final controller = _controllerWithText('Preset dock document.');
      addTearDown(controller.dispose);
      double? resizedWidth;

      await _pumpWorkspace(
        tester,
        controller: controller,
        editingMode: DocumentEditingMode.editing,
        activeWorkspacePanel: DocumentWorkspacePanelId.findReplace,
        workspacePanel: const Text('Preset find content'),
        onWorkspacePanelWidthChanged: (width) => resizedWidth = width,
      );

      await tester.tap(find.byKey(DocumentWorkspacePanelWidthMenu.buttonKey));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          DocumentWorkspacePanelWidthMenu.optionKey(
            DocumentWorkspacePanelWidthPreset.expanded,
          ),
        ),
      );

      expect(resizedWidth, DocumentWorkspacePanelDock.maxSideWidth);
    });

    testWidgets('stacks the utility dock when the side review hub is open', (
      tester,
    ) async {
      useViewport(tester);
      final controller = _controllerWithText('Stacked dock document.');
      addTearDown(controller.dispose);

      await _pumpWorkspace(
        tester,
        controller: controller,
        editingMode: DocumentEditingMode.editing,
        activeSidePanel: DocumentSidePanel.review,
        activeWorkspacePanel: DocumentWorkspacePanelId.findReplace,
        workspacePanel: const Text('Stacked find content'),
      );

      expect(find.byKey(DocumentWorkspacePanelDock.dockKey), findsOneWidget);

      final dockSize = tester.getSize(
        find.byKey(DocumentWorkspacePanelDock.dockKey),
      );
      expect(dockSize.height, DocumentWorkspacePanelDock.stackedHeight);
      expect(dockSize.width, greaterThan(DocumentWorkspacePanelDock.sideWidth));
      expect(
        find.byKey(DocumentWorkspacePanelDock.resizeHandleKey),
        findsNothing,
      );
      expect(
        find.byKey(DocumentWorkspacePanelWidthMenu.buttonKey),
        findsNothing,
      );
    });

    testWidgets('switches utility panels from the dock switcher', (
      tester,
    ) async {
      useViewport(tester);
      final controller = _controllerWithText('Switchable dock document.');
      addTearDown(controller.dispose);
      DocumentWorkspacePanelId? selectedPanel;

      await _pumpWorkspace(
        tester,
        controller: controller,
        editingMode: DocumentEditingMode.editing,
        activeWorkspacePanel: DocumentWorkspacePanelId.statistics,
        workspacePanel: const Text('Switchable dock content'),
        onWorkspacePanelChanged: (panel) => selectedPanel = panel,
      );

      await tester.tap(
        find.byKey(
          DocumentWorkspacePanelDock.panelButtonKey(
            DocumentWorkspacePanelId.aiAssistant,
          ),
        ),
      );

      expect(selectedPanel, DocumentWorkspacePanelId.aiAssistant);
    });

    testWidgets('locks mutating dock switcher options in viewing mode', (
      tester,
    ) async {
      useViewport(tester);
      final controller = _controllerWithText('Locked dock document.');
      addTearDown(controller.dispose);
      DocumentWorkspacePanelId? selectedPanel;

      await _pumpWorkspace(
        tester,
        controller: controller,
        editingMode: DocumentEditingMode.viewing,
        activeWorkspacePanel: DocumentWorkspacePanelId.statistics,
        workspacePanel: const Text('Locked dock content'),
        onWorkspacePanelChanged: (panel) => selectedPanel = panel,
      );

      final aiButton = tester.widget<IconButton>(
        find.byKey(
          DocumentWorkspacePanelDock.panelButtonKey(
            DocumentWorkspacePanelId.aiAssistant,
          ),
        ),
      );
      final insertButton = tester.widget<IconButton>(
        find.byKey(
          DocumentWorkspacePanelDock.panelButtonKey(
            DocumentWorkspacePanelId.insert,
          ),
        ),
      );

      expect(aiButton.onPressed, isNull);
      expect(insertButton.onPressed, isNull);

      await tester.tap(
        find.byKey(
          DocumentWorkspacePanelDock.panelButtonKey(
            DocumentWorkspacePanelId.findReplace,
          ),
        ),
      );

      expect(selectedPanel, DocumentWorkspacePanelId.findReplace);
    });
  });
}

Future<void> _pumpWorkspace(
  WidgetTester tester, {
  required quill.QuillController controller,
  required DocumentEditingMode editingMode,
  bool showOutline = false,
  bool showPageNavigator = false,
  double width = 1060,
  DocumentSidePanel? activeSidePanel,
  DocumentWorkspacePanelId? activeWorkspacePanel,
  Widget? workspacePanel,
  double workspacePanelWidth = DocumentWorkspacePanelDock.defaultSideWidth,
  DocumentWorkspaceNavigationState? navigationState,
  ValueChanged<DocumentSidePanel>? onSidePanelChanged,
  ValueChanged<DocumentEditingMode>? onEditingModeChanged,
  VoidCallback? onCloseSidePanel,
  VoidCallback? onToggleStatistics,
  VoidCallback? onToggleFindReplace,
  VoidCallback? onToggleAIAssistant,
  VoidCallback? onToggleInsertMenu,
  ValueChanged<DocumentWorkspacePanelId>? onWorkspacePanelChanged,
  ValueChanged<double>? onWorkspacePanelWidthChanged,
  VoidCallback? onCloseWorkspacePanel,
  VoidCallback? onToggleOutline,
  VoidCallback? onTogglePageNavigator,
  VoidCallback? onOpenOutline,
  VoidCallback? onOpenPageNavigator,
  VoidCallback? onCloseNavigationPanel,
}) async {
  final focusNode = FocusNode();
  addTearDown(focusNode.dispose);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        localizationsDelegates: const [
          quill.FlutterQuillLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: Scaffold(
          body: SizedBox(
            width: width,
            height: 720,
            child: DocumentEditorWorkspace(
              documentState: DocumentState(
                controller: controller,
                metadata: DocumentMetadata(
                  id: 'doc-1',
                  title: 'Proposal',
                  createdAt: DateTime(2026),
                  modifiedAt: DateTime(2026, 1, 2),
                ),
              ),
              statistics: DocumentTextStatistics.fromText(
                controller.document.toPlainText(),
              ),
              navigationState:
                  navigationState ??
                  DocumentWorkspaceNavigationState.fromVisibility(
                    showOutline: showOutline,
                    showPageNavigator: showPageNavigator,
                  ),
              activeSidePanel: activeSidePanel,
              activeWorkspacePanel: activeWorkspacePanel,
              workspacePanel: workspacePanel,
              workspacePanelWidth: workspacePanelWidth,
              editingMode: editingMode,
              focusNode: focusNode,
              onSidePanelChanged: onSidePanelChanged,
              onEditingModeChanged: onEditingModeChanged,
              onCloseSidePanel: onCloseSidePanel,
              onToggleStatistics: onToggleStatistics,
              onToggleFindReplace: onToggleFindReplace,
              onToggleAIAssistant: onToggleAIAssistant,
              onToggleInsertMenu: onToggleInsertMenu,
              onWorkspacePanelChanged: onWorkspacePanelChanged,
              onWorkspacePanelWidthChanged: onWorkspacePanelWidthChanged,
              onCloseWorkspacePanel: onCloseWorkspacePanel,
              onToggleOutline: onToggleOutline,
              onTogglePageNavigator: onTogglePageNavigator,
              onOpenOutline: onOpenOutline,
              onOpenPageNavigator: onOpenPageNavigator,
              onCloseNavigationPanel: onCloseNavigationPanel,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 1));
}

quill.QuillController _controllerWithText(String text) {
  final controller = quill.QuillController.basic();
  controller.document.insert(0, text);
  return controller;
}

Finder _activityFinder(DocumentWorkspaceActivityId id) {
  return find.byKey(DocumentWorkspaceActivityBar.itemKey(id));
}
