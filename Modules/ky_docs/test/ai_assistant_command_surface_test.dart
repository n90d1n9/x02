import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/aiaction.dart';
import 'package:ky_docs/docx/models/aiassistant_service.dart';
import 'package:ky_docs/docx/widgets/ai_assistant/ai_assistant_command_surface.dart';

void main() {
  group('AIAssistantCommandSurface', () {
    testWidgets('routes grouped actions when the assistant is configured', (
      tester,
    ) async {
      AIAction? selectedAction;

      await _pumpSurface(
        tester,
        hasApiKey: true,
        onActionSelected: (action) => selectedAction = action,
      );

      await tester.tap(_actionFinder(AIAction.improve));

      expect(find.text('Refine'), findsOneWidget);
      expect(find.text('Shape'), findsOneWidget);
      expect(selectedAction, AIAction.improve);
    });

    testWidgets('routes setup from actions when the assistant needs a key', (
      tester,
    ) async {
      var configured = false;
      AIAction? selectedAction;

      await _pumpSurface(
        tester,
        hasApiKey: false,
        onConfigure: () => configured = true,
        onActionSelected: (action) => selectedAction = action,
      );

      await tester.tap(_actionFinder(AIAction.improve));

      expect(configured, isTrue);
      expect(selectedAction, isNull);
      expect(find.text('Setup required'), findsOneWidget);
    });

    testWidgets('routes result card actions', (tester) async {
      final actions = <String>[];

      await _pumpSurface(
        tester,
        hasApiKey: true,
        result: 'Sharper writing.',
        onCopyResult: () => actions.add('copy'),
        onInsertResult: () => actions.add('insert'),
        onReplaceResult: () => actions.add('replace'),
        onClearResult: () => actions.add('clear'),
      );

      await tester.tap(find.text('Copy'));
      await tester.tap(find.text('Insert'));
      await tester.tap(find.text('Replace'));
      await tester.tap(find.byTooltip('Close'));

      expect(find.text('AI Suggestion'), findsOneWidget);
      expect(actions, ['copy', 'insert', 'replace', 'clear']);
    });

    testWidgets('supports embedded dock mode without duplicate title', (
      tester,
    ) async {
      await _pumpSurface(tester, hasApiKey: true, showHeader: false);

      expect(find.text('AI Writing Assistant'), findsNothing);
      expect(find.text('Ready'), findsOneWidget);
      expect(find.text('Full document'), findsOneWidget);
      expect(find.text('Refine'), findsOneWidget);
    });
  });
}

Finder _actionFinder(AIAction action) {
  return find.byKey(
    ValueKey('${AIAssistantCommandSurface.actionPrefixKey}-$action'),
  );
}

Future<void> _pumpSurface(
  WidgetTester tester, {
  required bool hasApiKey,
  String? result,
  VoidCallback? onConfigure,
  ValueChanged<AIAction>? onActionSelected,
  VoidCallback? onCopyResult,
  VoidCallback? onInsertResult,
  VoidCallback? onReplaceResult,
  VoidCallback? onClearResult,
  bool showHeader = true,
}) {
  final aiService = AIAssistantService();

  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 920,
          child: AIAssistantCommandSurface(
            hasApiKey: hasApiKey,
            isProcessing: false,
            result: result,
            contextLabel: 'Full document',
            actionLabelBuilder: aiService.getActionLabel,
            actionIconBuilder: aiService.getActionIcon,
            onConfigure: onConfigure ?? () {},
            onActionSelected: onActionSelected ?? (_) {},
            onCopyResult: onCopyResult ?? () {},
            onInsertResult: onInsertResult ?? () {},
            onReplaceResult: onReplaceResult ?? () {},
            onClearResult: onClearResult ?? () {},
            showHeader: showHeader,
          ),
        ),
      ),
    ),
  );
}
