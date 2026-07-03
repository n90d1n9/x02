import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/panel/document_panel_slider_control.dart';

void main() {
  group('DocumentPanelSliderControl', () {
    testWidgets('renders labeled slider and routes value changes', (
      tester,
    ) async {
      var value = 12.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return DocumentPanelSliderControl(
                  icon: Icons.format_size,
                  label: 'Font size',
                  valueLabel: '${value.toInt()} pt',
                  description: 'Tune exported body text.',
                  value: value,
                  min: 8,
                  max: 24,
                  divisions: 16,
                  onChanged: (nextValue) => setState(() => value = nextValue),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.format_size), findsOneWidget);
      expect(find.text('Font size'), findsOneWidget);
      expect(find.text('12 pt'), findsOneWidget);
      expect(find.text('Tune exported body text.'), findsOneWidget);

      await tester.drag(find.byType(Slider), const Offset(120, 0));
      await tester.pump();

      expect(value, greaterThan(12));
    });

    testWidgets('clamps out of range values before rendering', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentPanelSliderControl(
              label: 'Line spacing',
              valueLabel: '4.0',
              value: 4,
              min: 1,
              max: 3,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));

      expect(slider.value, 3);
    });
  });
}
