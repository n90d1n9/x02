import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/component.dart';
import 'package:ky_slide/models/selection_identity.dart';
import 'package:ky_slide/widgets/canvas/selection_identity_chip.dart';

void main() {
  testWidgets('selection identity chip renders object title and state', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF101114),
          body: Center(
            child: SelectionIdentityChip(
              accentColor: const Color(0xFF38BDF8),
              identity: const SelectionIdentity(
                title: 'Hero headline',
                typeLabel: 'Text',
                type: ComponentType.richText,
                isLocked: true,
                isVisible: true,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Hero headline'), findsOneWidget);
    expect(find.text('Text / Locked'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });
}
