import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/slide_navigator_density.dart';
import 'package:ky_slide/widgets/sidebar/slide_navigator_density_control.dart';

void main() {
  testWidgets('slide navigator density control selects a density', (
    tester,
  ) async {
    var selected = SlideNavigatorDensity.comfortable;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: StatefulBuilder(
              builder: (context, setState) {
                return SlideNavigatorDensityControl(
                  density: selected,
                  accentColor: const Color(0xFF2563EB),
                  onSelected: (value) {
                    setState(() => selected = value);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    expect(find.byTooltip('Compact thumbnails'), findsOneWidget);
    expect(find.byTooltip('Comfortable thumbnails'), findsOneWidget);

    await tester.tap(find.byTooltip('Compact thumbnails'));
    await tester.pumpAndSettle();

    expect(selected, SlideNavigatorDensity.compact);

    await tester.tap(find.byTooltip('Comfortable thumbnails'));
    await tester.pumpAndSettle();

    expect(selected, SlideNavigatorDensity.comfortable);
  });
}
