import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/panel/document_panel_shell.dart';

void main() {
  group('DocumentPanelShell', () {
    testWidgets('wraps content in a left-bordered surface frame', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DocumentPanelShell(child: Text('Panel body'))),
        ),
      );

      expect(find.text('Panel body'), findsOneWidget);
      expect(_framedSurfaceFinder(), findsOneWidget);
    });

    testWidgets('returns content directly when frame is hidden', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DocumentPanelShell(
              showFrame: false,
              child: Text('Unframed body'),
            ),
          ),
        ),
      );

      expect(find.text('Unframed body'), findsOneWidget);
      expect(_framedSurfaceFinder(), findsNothing);
    });
  });
}

Finder _framedSurfaceFinder() {
  return find.byWidgetPredicate((widget) {
    if (widget is! DecoratedBox) return false;
    final decoration = widget.decoration;
    if (decoration is! BoxDecoration) return false;
    final border = decoration.border;
    return border is Border && border.left.style != BorderStyle.none;
  });
}
