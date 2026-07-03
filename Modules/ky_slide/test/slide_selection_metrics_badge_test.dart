import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/component.dart';
import 'package:ky_slide/models/presentation_component.dart';
import 'package:ky_slide/widgets/canvas/slide_selection_metrics_badge.dart';

void main() {
  testWidgets('selection metrics badge renders selected object geometry', (
    tester,
  ) async {
    await _pumpBadge(
      tester,
      PresentationComponent(
        id: 'shape',
        type: ComponentType.shape,
        position: const Offset(80.4, 96.6),
        size: const Size(180.2, 72.8),
      ),
    );

    expect(find.text('X 80'), findsOneWidget);
    expect(find.text('Y 97'), findsOneWidget);
    expect(find.text('W 180'), findsOneWidget);
    expect(find.text('H 73'), findsOneWidget);
    expect(find.textContaining('R '), findsNothing);
  });

  testWidgets('selection metrics badge includes rotation when rotated', (
    tester,
  ) async {
    await _pumpBadge(
      tester,
      PresentationComponent(
        id: 'shape',
        type: ComponentType.shape,
        position: const Offset(16, 20),
        size: const Size(120, 80),
        rotation: 15.4,
      ),
    );

    expect(find.text('R 15'), findsOneWidget);
  });
}

Future<void> _pumpBadge(
  WidgetTester tester,
  PresentationComponent component,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 640,
          height: 360,
          child: Stack(
            children: [
              SlideSelectionMetricsBadge(
                component: component,
                slideSize: const Size(640, 360),
                zoom: 1,
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
