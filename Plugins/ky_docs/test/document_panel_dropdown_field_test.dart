import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/panel/document_panel_dropdown_field.dart';

void main() {
  group('DocumentPanelDropdownField', () {
    testWidgets('renders decorated dropdown and routes selection changes', (
      tester,
    ) async {
      var selectedValue = 'bar';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return DocumentPanelDropdownField<String>(
                  value: selectedValue,
                  labelText: 'Chart type',
                  helperText: 'Choose the chart visualization.',
                  prefixIcon: Icons.stacked_bar_chart,
                  items: const [
                    DropdownMenuItem(value: 'bar', child: Text('BAR')),
                    DropdownMenuItem(value: 'line', child: Text('LINE')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => selectedValue = value);
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.stacked_bar_chart), findsOneWidget);
      expect(find.text('Chart type'), findsOneWidget);
      expect(find.text('Choose the chart visualization.'), findsOneWidget);
      expect(find.text('BAR'), findsOneWidget);

      tester
          .widget<DropdownButtonFormField<String>>(
            find.byType(DropdownButtonFormField<String>),
          )
          .onChanged
          ?.call('line');
      await tester.pump();

      expect(selectedValue, 'line');
    });
  });
}
