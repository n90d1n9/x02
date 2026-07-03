import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/component.dart';
import 'package:ky_slide/models/presentation.dart';
import 'package:ky_slide/models/presentation_component.dart';
import 'package:ky_slide/models/slide.dart';
import 'package:ky_slide/models/style/presentation_theme.dart';
import 'package:ky_slide/services/media_picker_service.dart';
import 'package:ky_slide/states/component_provider.dart';
import 'package:ky_slide/states/history_provider.dart';
import 'package:ky_slide/states/media_insert_actions_provider.dart';
import 'package:ky_slide/states/presentation_provider.dart';

void main() {
  test('inserts a picked image and returns UI feedback', () async {
    final imageBytes = Uint8List.fromList([1, 2, 3]);
    final container = _container(
      picker: _FakeMediaPickerService(
        () async => PickedImageMedia(bytes: imageBytes, fileName: 'chart.png'),
      ),
    );
    addTearDown(container.dispose);

    final result = await container
        .read(mediaInsertActionsProvider)
        .addImageFromPicker();

    expect(result.status, MediaInsertStatus.inserted);
    expect(result.message, 'Inserted chart.png.');
    expect(result.componentId, isNotNull);

    final component = _components(container).last;
    expect(component.id, result.componentId);
    expect(component.type, ComponentType.image);
    expect(component.imageData, imageBytes);
    expect(container.read(selectedComponentProvider), component.id);
    expect(container.read(historyProvider).undoLabel, 'Add image');
  });

  test('returns cancelled when the picker is dismissed', () async {
    final container = _container(
      picker: _FakeMediaPickerService(() async => null),
    );
    addTearDown(container.dispose);

    final result = await container
        .read(mediaInsertActionsProvider)
        .addImageFromPicker();

    expect(result.status, MediaInsertStatus.cancelled);
    expect(result.message, isNull);
    expect(_components(container), hasLength(1));
  });

  test('returns failed when the picker cannot load bytes', () async {
    final container = _container(
      picker: _FakeMediaPickerService(
        () async => throw const MediaPickerException('Image bytes missing.'),
      ),
    );
    addTearDown(container.dispose);

    final result = await container
        .read(mediaInsertActionsProvider)
        .addImageFromPicker();

    expect(result.status, MediaInsertStatus.failed);
    expect(result.message, 'Image bytes missing.');
    expect(_components(container), hasLength(1));
  });
}

ProviderContainer _container({required MediaPickerService picker}) {
  return ProviderContainer(
    overrides: [
      presentationProvider.overrideWith(
        (ref) => PresentationNotifier(initialPresentation: _presentation()),
      ),
      mediaPickerServiceProvider.overrideWithValue(picker),
    ],
  );
}

Presentation _presentation() {
  return Presentation(
    id: 'media-insert-actions-test',
    title: 'Media Insert Actions Test',
    slides: [
      Slide(
        id: 'slide',
        components: [
          PresentationComponent(
            id: 'title',
            type: ComponentType.richText,
            position: const Offset(40, 40),
            size: const Size(240, 80),
          ),
        ],
      ),
    ],
    theme: PresentationTheme(
      id: 'test-theme',
      name: 'Test Theme',
      primaryColor: const Color(0xFF2563EB),
      secondaryColor: const Color(0xFF14B8A6),
      backgroundColor: const Color(0xFF0F172A),
      textColor: Colors.white,
      titleStyle: const TextStyle(color: Colors.white, fontSize: 48),
      bodyStyle: const TextStyle(color: Colors.white70, fontSize: 20),
      colorPalette: const [Color(0xFF2563EB), Color(0xFF14B8A6)],
    ),
  );
}

List<PresentationComponent> _components(ProviderContainer container) {
  final presentation = container.read(presentationProvider);
  return presentation.slides[presentation.currentSlideIndex].components;
}

class _FakeMediaPickerService implements MediaPickerService {
  final Future<PickedImageMedia?> Function() pickImageCallback;

  const _FakeMediaPickerService(this.pickImageCallback);

  @override
  Future<PickedImageMedia?> pickImage() => pickImageCallback();
}
