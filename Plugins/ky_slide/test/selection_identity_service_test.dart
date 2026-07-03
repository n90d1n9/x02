import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/component.dart';
import 'package:ky_slide/models/presentation_component.dart';
import 'package:ky_slide/models/rich_text_content.dart';
import 'package:ky_slide/services/selection_identity_service.dart';

void main() {
  const service = SelectionIdentityService();

  test('uses layer name and state for selected object identity', () {
    final identity = service.identityFor(
      PresentationComponent(
        id: 'hero',
        type: ComponentType.richText,
        layerName: 'Hero headline',
        position: Offset.zero,
        size: const Size(320, 90),
        isLocked: true,
      ),
    );

    expect(identity.title, 'Hero headline');
    expect(identity.typeLabel, 'Text');
    expect(identity.type, ComponentType.richText);
    expect(identity.stateLabel, 'Locked');
  });

  test('falls back to visible rich text copy for unnamed objects', () {
    final identity = service.identityFor(
      PresentationComponent(
        id: 'caption',
        type: ComponentType.richText,
        position: Offset.zero,
        size: const Size(240, 70),
        richText: RichTextContent(
          text: '  \nLaunch metrics\nSecondary line',
          style: const TextStyle(),
        ),
      ),
    );

    expect(identity.title, 'Launch metrics');
    expect(identity.stateLabel, 'Editable');
  });
}
