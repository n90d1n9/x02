import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/widgets/editor/editor_workspace_shell.dart';

void main() {
  testWidgets('editor workspace shell shows both panels on wide layouts', (
    tester,
  ) async {
    _setViewport(tester, width: 1200);
    await tester.pumpWidget(_workspace(width: 1200));

    expect(find.text('Slide panel content'), findsOneWidget);
    expect(find.text('Canvas'), findsOneWidget);
    expect(find.text('Inspector panel content'), findsOneWidget);
  });

  testWidgets(
    'editor workspace shell keeps slide navigation on medium widths',
    (tester) async {
      _setViewport(tester, width: 980);
      await tester.pumpWidget(_workspace(width: 980));

      expect(find.text('Slide panel content'), findsOneWidget);
      expect(find.text('Canvas'), findsOneWidget);
      expect(find.text('Inspector panel content'), findsNothing);
    },
  );

  testWidgets('editor workspace shell can show inspector without navigation', (
    tester,
  ) async {
    _setViewport(tester, width: 860);
    await tester.pumpWidget(
      _workspace(
        width: 860,
        showSlideNavigator: false,
        showPropertiesPanel: true,
      ),
    );

    expect(find.text('Slides'), findsNothing);
    expect(find.text('Canvas'), findsOneWidget);
    expect(find.text('Inspector panel content'), findsOneWidget);
  });

  testWidgets('editor workspace shell offers compact access to hidden panels', (
    tester,
  ) async {
    _setViewport(tester, width: 700);
    await tester.pumpWidget(_workspace(width: 700));

    expect(find.text('Slide panel content'), findsNothing);
    expect(find.text('Inspector panel content'), findsNothing);
    expect(find.byTooltip('Open slide navigator panel'), findsOneWidget);
    expect(find.byTooltip('Open inspector panel'), findsOneWidget);

    await tester.tap(find.byTooltip('Open slide navigator panel'));
    await tester.pumpAndSettle();

    expect(find.text('Slide navigator'), findsOneWidget);
    expect(find.text('Slide panel content'), findsOneWidget);
  });
}

void _setViewport(WidgetTester tester, {required double width}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 700);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _workspace({
  required double width,
  bool showSlideNavigator = true,
  bool showPropertiesPanel = true,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          height: 620,
          child: EditorWorkspaceShell(
            showSlideNavigator: showSlideNavigator,
            showPropertiesPanel: showPropertiesPanel,
            showSpeakerNotes: true,
            slideNavigator: const _TestPanel(label: 'Slide panel content'),
            toolbar: const _TestBar(label: 'Toolbar'),
            canvasArea: const _TestPanel(label: 'Canvas'),
            speakerNotes: const _TestBar(label: 'Notes'),
            statusBar: const _TestBar(label: 'Status'),
            propertiesPanel: const _TestPanel(label: 'Inspector panel content'),
          ),
        ),
      ),
    ),
  );
}

/// Small fixed-height test bar used to exercise editor workspace composition.
class _TestBar extends StatelessWidget {
  final String label;

  const _TestBar({required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 48, child: Center(child: Text(label)));
  }
}

/// Small test panel used to verify editor workspace side-panel visibility.
class _TestPanel extends StatelessWidget {
  final String label;

  const _TestPanel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(label));
  }
}
