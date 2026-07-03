import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/page_margin_preset.dart';

void main() {
  group('DocumentPageMarginPreset', () {
    test('exposes known point-based margin presets', () {
      expect(DocumentPageMarginPreset.normal.margins, const EdgeInsets.all(72));
      expect(DocumentPageMarginPreset.narrow.margins, const EdgeInsets.all(36));
      expect(
        DocumentPageMarginPreset.wide.margins,
        const EdgeInsets.symmetric(horizontal: 108, vertical: 72),
      );
      expect(DocumentPageMarginPreset.compact.label, 'Compact');
    });

    test('matches exact preset margins', () {
      expect(
        DocumentPageMarginPresetMatcher.match(const EdgeInsets.all(36)),
        DocumentPageMarginPreset.narrow,
      );
      expect(
        DocumentPageMarginPresetMatcher.match(
          const EdgeInsets.fromLTRB(35, 36, 36, 36),
        ),
        isNull,
      );
    });
  });
}
