import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/object_style_preset.dart';
import 'package:ky_slide/models/rich_text_content.dart';
import 'package:ky_slide/models/selection_quick_format_action.dart';
import 'package:ky_slide/models/text_paragraph_format.dart';
import 'package:ky_slide/models/text_style_preset.dart';
import 'package:ky_slide/widgets/canvas/selection_quick_format_menu.dart';

void main() {
  testWidgets(
    'selection quick format menu renders commands and dispatches fill',
    (tester) async {
      SelectionQuickFormatAction? selectedAction;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xFF101114),
            body: Center(
              child: SelectionQuickFormatMenu(
                enabled: true,
                accentColor: const Color(0xFF2563EB),
                secondaryColor: const Color(0xFF14B8A6),
                selectedPreset: ObjectStylePreset.soft,
                fillColors: const [Color(0xFF2563EB), Color(0xFF14B8A6)],
                selectedFillColor: const Color(0xFF2563EB),
                selectedBorderColor: const Color(0xFF14B8A6),
                selectedBorderWidth: 2,
                selectedOpacity: 0.75,
                selectedGlowEnabled: true,
                selectedGlowColor: const Color(0xFF14B8A6),
                onSelected: (action) => selectedAction = action,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Quick format'));
      await tester.pumpAndSettle();

      expect(find.text('Presets'), findsOneWidget);
      expect(find.text('Fill'), findsOneWidget);
      expect(find.text('Outline'), findsWidgets);
      expect(find.text('Outline width'), findsOneWidget);
      expect(find.text('Opacity'), findsOneWidget);
      expect(find.text('Effects'), findsOneWidget);
      expect(find.byTooltip('Apply Soft preset'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byTooltip('No fill'), findsOneWidget);
      expect(find.byTooltip('Fill #2563EB'), findsOneWidget);
      expect(find.byTooltip('No outline'), findsWidgets);
      expect(find.byTooltip('Outline #14B8A6'), findsOneWidget);
      expect(find.byTooltip('2 px outline'), findsOneWidget);
      expect(find.byTooltip('75% opacity'), findsOneWidget);
      expect(find.byTooltip('No glow'), findsOneWidget);
      expect(find.byTooltip('Glow on'), findsOneWidget);
      expect(find.byTooltip('Glow #14B8A6'), findsOneWidget);

      await tester.tap(find.byTooltip('Apply Soft preset'));
      await tester.pumpAndSettle();

      expect(selectedAction?.type, SelectionQuickFormatActionType.objectPreset);
      expect(selectedAction?.preset, ObjectStylePreset.soft);

      await tester.tap(find.byTooltip('Quick format'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Fill #2563EB'));
      await tester.pumpAndSettle();

      expect(selectedAction?.type, SelectionQuickFormatActionType.fillColor);
      expect(selectedAction?.color, const Color(0xFF2563EB));

      await tester.tap(find.byTooltip('Quick format'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('No fill'));
      await tester.pumpAndSettle();

      expect(selectedAction?.type, SelectionQuickFormatActionType.clearFill);

      await tester.tap(find.byTooltip('Quick format'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('No outline').first);
      await tester.pumpAndSettle();

      expect(selectedAction?.type, SelectionQuickFormatActionType.clearBorder);

      await tester.tap(find.byTooltip('Quick format'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('No glow'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('No glow'));
      await tester.pumpAndSettle();

      expect(selectedAction?.type, SelectionQuickFormatActionType.glowEnabled);
      expect(selectedAction?.enabled, isFalse);

      await tester.tap(find.byTooltip('Quick format'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Glow on'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Glow on'));
      await tester.pumpAndSettle();

      expect(selectedAction?.type, SelectionQuickFormatActionType.glowEnabled);
      expect(selectedAction?.enabled, isTrue);

      await tester.tap(find.byTooltip('Quick format'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Glow #14B8A6'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Glow #14B8A6'));
      await tester.pumpAndSettle();

      expect(selectedAction?.type, SelectionQuickFormatActionType.glowColor);
      expect(selectedAction?.color, const Color(0xFF14B8A6));
    },
  );

  testWidgets(
    'selection quick format menu renders text commands for rich text',
    (tester) async {
      SelectionQuickFormatAction? selectedAction;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xFF101114),
            body: Center(
              child: SelectionQuickFormatMenu(
                enabled: true,
                accentColor: const Color(0xFF2563EB),
                secondaryColor: const Color(0xFF14B8A6),
                fillColors: const [Color(0xFF2563EB), Color(0xFF14B8A6)],
                selectedFillColor: const Color(0xFF2563EB),
                selectedBorderColor: const Color(0xFF14B8A6),
                selectedBorderWidth: 2,
                selectedOpacity: 0.75,
                selectedGlowEnabled: true,
                selectedGlowColor: const Color(0xFF14B8A6),
                activeParagraphListStyle: TextParagraphListStyle.bullet,
                selectedTextPreset: TextStylePreset.body,
                richText: RichTextContent(
                  text: 'Quarterly update',
                  style: const TextStyle(
                    color: Color(0xFF14B8A6),
                    fontFamily: 'Inter',
                    fontSize: 24,
                    height: 1.3,
                    letterSpacing: 0.5,
                    backgroundColor: Color(0xFFFFF3BF),
                  ),
                  isBold: true,
                  alignment: TextAlign.center,
                ),
                onSelected: (action) => selectedAction = action,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Quick format'));
      await tester.pumpAndSettle();

      expect(find.text('Text'), findsOneWidget);
      expect(find.byTooltip('Body text preset selected'), findsOneWidget);
      expect(find.byTooltip('Apply Quote text preset'), findsOneWidget);
      expect(find.byTooltip('Remove bold'), findsOneWidget);
      expect(find.byTooltip('Strikethrough text'), findsOneWidget);
      expect(find.byTooltip('Justify align text'), findsOneWidget);
      expect(find.byTooltip('Font family Inter'), findsOneWidget);
      expect(find.byTooltip('Font family Poppins'), findsOneWidget);
      expect(find.byTooltip('32 pt text'), findsOneWidget);
      expect(find.byTooltip('1.3x line spacing'), findsOneWidget);
      expect(find.byTooltip('0.5 pt character spacing'), findsOneWidget);
      expect(find.byTooltip('Text #2563EB'), findsOneWidget);
      expect(find.byTooltip('Clear highlight'), findsOneWidget);
      expect(find.byTooltip('Highlight #FFF3BF'), findsOneWidget);
      expect(find.byTooltip('Highlight #BBF7D0'), findsOneWidget);
      expect(find.text('Effects'), findsOneWidget);
      expect(find.byTooltip('Glow #14B8A6'), findsOneWidget);
      expect(find.text('Paragraph'), findsOneWidget);
      expect(find.byTooltip('Remove bullets'), findsOneWidget);
      expect(find.byTooltip('Increase indent'), findsOneWidget);
      expect(find.byTooltip('UPPERCASE'), findsOneWidget);

      await tester.tap(find.byTooltip('Apply Quote text preset'));
      await tester.pumpAndSettle();

      expect(selectedAction?.type, SelectionQuickFormatActionType.textPreset);
      expect(selectedAction?.textPreset, TextStylePreset.quote);

      await tester.tap(find.byTooltip('Quick format'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('32 pt text'));
      await tester.pumpAndSettle();

      expect(selectedAction?.type, SelectionQuickFormatActionType.textFontSize);
      expect(selectedAction?.value, 32);

      await tester.tap(find.byTooltip('Quick format'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Font family Poppins'));
      await tester.pumpAndSettle();

      expect(
        selectedAction?.type,
        SelectionQuickFormatActionType.textFontFamily,
      );
      expect(selectedAction?.textValue, 'Poppins');

      await tester.tap(find.byTooltip('Quick format'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('1.5x line spacing'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('1.5x line spacing'));
      await tester.pumpAndSettle();

      expect(
        selectedAction?.type,
        SelectionQuickFormatActionType.textLineHeight,
      );
      expect(selectedAction?.value, 1.5);

      await tester.tap(find.byTooltip('Quick format'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('1.5 pt character spacing'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('1.5 pt character spacing'));
      await tester.pumpAndSettle();

      expect(
        selectedAction?.type,
        SelectionQuickFormatActionType.textLetterSpacing,
      );
      expect(selectedAction?.value, 1.5);

      await tester.tap(find.byTooltip('Quick format'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Highlight #BBF7D0'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Highlight #BBF7D0'));
      await tester.pumpAndSettle();

      expect(
        selectedAction?.type,
        SelectionQuickFormatActionType.textHighlightColor,
      );
      expect(selectedAction?.color, const Color(0xFFBBF7D0));

      await tester.tap(find.byTooltip('Quick format'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Strikethrough text'));
      await tester.pumpAndSettle();

      expect(
        selectedAction?.type,
        SelectionQuickFormatActionType.textStrikethrough,
      );
      expect(selectedAction?.enabled, isTrue);

      await tester.tap(find.byTooltip('Quick format'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Justify align text'));
      await tester.pumpAndSettle();

      expect(
        selectedAction?.type,
        SelectionQuickFormatActionType.textAlignment,
      );
      expect(selectedAction?.alignment, TextAlign.justify);

      await tester.tap(find.byTooltip('Quick format'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Clear highlight'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Clear highlight'));
      await tester.pumpAndSettle();

      expect(
        selectedAction?.type,
        SelectionQuickFormatActionType.textClearHighlight,
      );

      await tester.tap(find.byTooltip('Quick format'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Remove bullets'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Remove bullets'));
      await tester.pumpAndSettle();

      expect(
        selectedAction?.type,
        SelectionQuickFormatActionType.paragraphListStyle,
      );
      expect(selectedAction?.paragraphListStyle, TextParagraphListStyle.none);

      await tester.tap(find.byTooltip('Quick format'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Increase indent'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Increase indent'));
      await tester.pumpAndSettle();

      expect(selectedAction?.type, SelectionQuickFormatActionType.textIndent);
      expect(selectedAction?.indentDirection, TextIndentDirection.increase);

      await tester.tap(find.byTooltip('Quick format'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('AA'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('AA'));
      await tester.pumpAndSettle();

      expect(selectedAction?.type, SelectionQuickFormatActionType.textCase);
      expect(selectedAction?.caseTransform, TextCaseTransform.uppercase);
    },
  );
}
