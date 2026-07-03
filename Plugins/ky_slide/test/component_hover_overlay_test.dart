import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/widgets/canvas/component_hover_overlay.dart';

void main() {
  testWidgets('component hover overlay renders object label and type', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: Color(0xFF101114),
          body: Center(
            child: SizedBox(
              width: 180,
              height: 72,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ComponentHoverOverlay(
                    label: 'Revenue card',
                    typeLabel: 'Rectangle',
                    isLocked: true,
                    accentColor: Color(0xFF38BDF8),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Revenue card'), findsOneWidget);
    expect(find.text('Rectangle'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });
}
