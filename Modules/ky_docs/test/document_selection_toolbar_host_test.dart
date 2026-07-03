import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/document_editing_mode.dart';
import 'package:ky_docs/docx/widgets/selection_toolbar/document_selection_toolbar.dart';
import 'package:ky_docs/docx/widgets/selection_toolbar/document_selection_toolbar_host.dart';

void main() {
  group('DocumentSelectionToolbarHost', () {
    testWidgets(
      'shows toolbar for expanded selections and toggles formatting',
      (tester) async {
        final controller = _controllerWithText('Selected text');
        addTearDown(controller.dispose);
        var focusRequested = false;

        await _pumpHost(
          tester,
          controller: controller,
          onRequestEditorFocus: () => focusRequested = true,
        );

        expect(find.byKey(DocumentSelectionToolbar.toolbarKey), findsNothing);

        controller.updateSelection(
          const TextSelection(baseOffset: 0, extentOffset: 8),
          quill.ChangeSource.local,
        );
        await tester.pump();

        expect(find.text('8 selected'), findsOneWidget);

        await tester.tap(find.byTooltip('Bold'));
        await tester.pump();
        await tester.tap(find.byTooltip('Underline'));
        await tester.pump();
        await tester.tap(find.byTooltip('Quote'));
        await tester.pump();

        final styledAttributes = controller.getSelectionStyle().attributes;
        expect(styledAttributes.containsKey(quill.Attribute.bold.key), isTrue);
        expect(
          styledAttributes.containsKey(quill.Attribute.underline.key),
          isTrue,
        );
        expect(
          styledAttributes.containsKey(quill.Attribute.blockQuote.key),
          isTrue,
        );

        await tester.tap(find.byTooltip('Clear formatting'));
        await tester.pump();

        final clearedAttributes = controller.getSelectionStyle().attributes;
        expect(
          clearedAttributes.containsKey(quill.Attribute.bold.key),
          isFalse,
        );
        expect(
          clearedAttributes.containsKey(quill.Attribute.underline.key),
          isFalse,
        );
        expect(
          clearedAttributes.containsKey(quill.Attribute.blockQuote.key),
          isFalse,
        );
        expect(focusRequested, isTrue);
      },
    );

    testWidgets('routes contextual review and AI actions', (tester) async {
      final controller = _controllerWithText('Selected text');
      addTearDown(controller.dispose);
      var commentsOpened = false;
      var improved = false;
      var trackChangesOpened = false;

      await _pumpHost(
        tester,
        controller: controller,
        onOpenComments: () => commentsOpened = true,
        onImproveSelection: () async => improved = true,
        onOpenTrackChanges: () => trackChangesOpened = true,
      );

      controller.updateSelection(
        const TextSelection(baseOffset: 0, extentOffset: 8),
        quill.ChangeSource.local,
      );
      await tester.pump();

      await tester.tap(find.byTooltip('Comment'));
      await tester.tap(find.byTooltip('Improve'));
      await tester.pump();
      await tester.tap(find.byTooltip('Suggest change'));

      expect(commentsOpened, isTrue);
      expect(improved, isTrue);
      expect(trackChangesOpened, isTrue);
    });

    testWidgets('uses copy-only selection tools in viewing mode', (
      tester,
    ) async {
      final controller = _controllerWithText('Selected text');
      addTearDown(controller.dispose);
      String? copiedText;
      var focusRequested = false;
      var commentsOpened = false;

      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedText =
                (call.arguments as Map<Object?, Object?>)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      await _pumpHost(
        tester,
        controller: controller,
        editingMode: DocumentEditingMode.viewing,
        onOpenComments: () => commentsOpened = true,
        onRequestEditorFocus: () => focusRequested = true,
      );

      controller.updateSelection(
        const TextSelection(baseOffset: 0, extentOffset: 8),
        quill.ChangeSource.local,
      );
      await tester.pump();

      expect(find.text('8 selected'), findsOneWidget);
      expect(find.text('Viewing'), findsOneWidget);
      expect(find.byTooltip('Copy'), findsOneWidget);
      expect(find.byTooltip('Bold'), findsNothing);
      expect(find.byTooltip('Underline'), findsNothing);
      expect(find.byTooltip('Quote'), findsNothing);
      expect(find.byTooltip('Clear formatting'), findsNothing);
      expect(find.byTooltip('Comment'), findsNothing);

      await tester.tap(find.byKey(DocumentSelectionToolbar.copyActionKey));
      await tester.pump();

      expect(copiedText, 'Selected');
      expect(focusRequested, isTrue);
      expect(commentsOpened, isFalse);
    });
  });
}

Future<void> _pumpHost(
  WidgetTester tester, {
  required quill.QuillController controller,
  DocumentEditingMode editingMode = DocumentEditingMode.editing,
  VoidCallback? onOpenComments,
  Future<void> Function()? onImproveSelection,
  VoidCallback? onOpenTrackChanges,
  VoidCallback? onRequestEditorFocus,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 640,
          height: 360,
          child: DocumentSelectionToolbarHost(
            controller: controller,
            editingMode: editingMode,
            onOpenComments: onOpenComments,
            onImproveSelection: onImproveSelection,
            onOpenTrackChanges: onOpenTrackChanges,
            onRequestEditorFocus: onRequestEditorFocus,
            child: const ColoredBox(color: Colors.white),
          ),
        ),
      ),
    ),
  );
}

quill.QuillController _controllerWithText(String text) {
  final controller = quill.QuillController.basic();
  controller.document.insert(0, text);
  controller.updateSelection(
    const TextSelection.collapsed(offset: 0),
    quill.ChangeSource.local,
  );
  return controller;
}
