import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_office_core/ky_office_core.dart';

import 'package:ky_slide/ky_slide.dart';
import 'package:ky_slide/models/component.dart';
import 'package:ky_slide/models/presentation.dart';
import 'package:ky_slide/models/presentation_component.dart';
import 'package:ky_slide/models/rich_text_content.dart';
import 'package:ky_slide/models/slide.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('exposes Office family product metadata', () {
    expect(kyPptOfficeProduct.id, 'slides');
    expect(kyPptOfficeProduct.familyName, 'Kaysir Office');
    expect(kyPptOfficeProduct.kind, KyOfficeProductKind.presentation);
    expect(kyPptOfficeProduct.supports('present'), isTrue);
  });

  test('serializes presentation models for slide engine handoff', () {
    final presentation = Presentation(
      id: 'deck-1',
      title: 'Quarterly Review',
      slides: [
        Slide(
          id: 'slide-1',
          title: 'Opening',
          components: [
            PresentationComponent(
              id: 'title-1',
              type: ComponentType.richText,
              position: const Offset(24, 32),
              size: const Size(320, 96),
              richText: RichTextContent(
                text: 'Hello Office',
                style: const TextStyle(
                  fontSize: 28,
                  color: Colors.black,
                  letterSpacing: 0.5,
                  backgroundColor: Color(0xFFFFF3BF),
                ),
                isStrikethrough: true,
              ),
            ),
          ],
        ),
      ],
    );

    final json = presentation.toJson();
    final roundTrip = Presentation.fromJson(json);

    expect(json['id'], 'deck-1');
    expect(json['slides'], hasLength(1));
    expect(roundTrip.title, 'Quarterly Review');
    expect(roundTrip.slides.single.components.single.id, 'title-1');
    expect(
      roundTrip.slides.single.components.single.richText?.text,
      'Hello Office',
    );
    expect(
      roundTrip.slides.single.components.single.richText?.style.letterSpacing,
      0.5,
    );
    expect(
      roundTrip.slides.single.components.single.richText?.style.backgroundColor,
      const Color(0xFFFFF3BF),
    );
    expect(
      roundTrip.slides.single.components.single.richText?.isStrikethrough,
      isTrue,
    );
  });
}
