import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/transform_feedback.dart';
import 'package:ky_slide/widgets/canvas/transform_feedback_badge.dart';

void main() {
  testWidgets('transform feedback badge renders move measurements', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 640,
            height: 360,
            child: Stack(
              children: [
                TransformFeedbackBadge(
                  feedback: TransformFeedback(
                    mode: TransformFeedbackMode.move,
                    position: Offset(124, 88),
                    size: Size(100, 60),
                    rotation: 0,
                  ),
                  slideSize: Size(640, 360),
                  zoom: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('MOVE'), findsOneWidget);
    expect(find.text('X 124  Y 88'), findsOneWidget);
    expect(find.byIcon(Icons.open_with), findsOneWidget);
  });

  testWidgets('transform feedback badge renders rotate measurements', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 640,
            height: 360,
            child: Stack(
              children: [
                TransformFeedbackBadge(
                  feedback: TransformFeedback(
                    mode: TransformFeedbackMode.rotate,
                    position: Offset(124, 88),
                    size: Size(100, 60),
                    rotation: 15,
                  ),
                  slideSize: Size(640, 360),
                  zoom: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('ROTATE'), findsOneWidget);
    expect(find.text('15 deg'), findsOneWidget);
    expect(find.byIcon(Icons.rotate_right), findsOneWidget);
  });
}
