import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/text_paragraph_format.dart';
import 'package:ky_slide/services/text_paragraph_formatting_service.dart';

void main() {
  const service = TextParagraphFormattingService();

  test(
    'applies bullet and numbered list markers while preserving indentation',
    () {
      const text = 'Revenue improved\n  Launch pilot';

      expect(
        service.applyListStyle(
          text: text,
          style: TextParagraphListStyle.bullet,
        ),
        '- Revenue improved\n  - Launch pilot',
      );
      expect(
        service.applyListStyle(
          text: '- Revenue improved\n  - Launch pilot',
          style: TextParagraphListStyle.numbered,
        ),
        '1. Revenue improved\n  2. Launch pilot',
      );
      expect(
        service.applyListStyle(
          text: '1. Revenue improved\n  2. Launch pilot',
          style: TextParagraphListStyle.none,
        ),
        'Revenue improved\n  Launch pilot',
      );
    },
  );

  test('detects active paragraph list style for consistent lists', () {
    expect(
      service.activeListStyle('- Revenue\n- Margin'),
      TextParagraphListStyle.bullet,
    );
    expect(
      service.activeListStyle('1. Revenue\n2. Margin'),
      TextParagraphListStyle.numbered,
    );
    expect(
      service.activeListStyle('- Revenue\n2. Margin'),
      TextParagraphListStyle.none,
    );
  });

  test('adjusts indentation and applies common text case transforms', () {
    const text = 'revenue improved\nlaunch pilot';

    expect(
      service.adjustIndent(text: text, direction: TextIndentDirection.increase),
      '  revenue improved\n  launch pilot',
    );
    expect(
      service.adjustIndent(
        text: '  revenue improved\n launch pilot',
        direction: TextIndentDirection.decrease,
      ),
      'revenue improved\nlaunch pilot',
    );
    expect(
      service.applyTextCase(text: text, transform: TextCaseTransform.title),
      'Revenue Improved\nLaunch Pilot',
    );
    expect(
      service.applyTextCase(text: text, transform: TextCaseTransform.uppercase),
      'REVENUE IMPROVED\nLAUNCH PILOT',
    );
    expect(
      service.applyTextCase(
        text: 'revenue improved. launch pilot',
        transform: TextCaseTransform.sentence,
      ),
      'Revenue improved. Launch pilot',
    );
  });
}
