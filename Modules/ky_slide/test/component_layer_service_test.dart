import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/component.dart';
import 'package:ky_slide/models/component_layer_filter.dart';
import 'package:ky_slide/models/presentation_component.dart';
import 'package:ky_slide/models/rich_text_content.dart';
import 'package:ky_slide/models/slide.dart';
import 'package:ky_slide/services/component_layer_service.dart';

void main() {
  test('layersFor returns visual top-to-bottom component order', () {
    const service = ComponentLayerService();
    final layers = service.layersFor(
      Slide(
        id: 'slide',
        components: [
          _shape(id: 'background', zIndex: 0),
          _shape(id: 'image', type: ComponentType.image, zIndex: 20),
          _text(id: 'title', text: 'Quarterly update', zIndex: 30),
          _shape(id: 'badge', type: ComponentType.circle, zIndex: 30),
          _shape(id: 'hidden-note', zIndex: -1, isVisible: false),
        ],
      ),
    );

    expect(layers.map((item) => item.component.id), [
      'badge',
      'title',
      'image',
      'background',
      'hidden-note',
    ]);
    expect(layers[1].title, 'Quarterly update');
    expect(layers[1].typeLabel, 'Text');
    expect(layers.last.typeLabel, 'Rectangle');
  });

  test('filterLayers matches title, type, id, and layer state', () {
    const service = ComponentLayerService();
    final layers = service.layersFor(
      Slide(
        id: 'slide',
        components: [
          _shape(id: 'background', zIndex: 0),
          _shape(id: 'hero-image', type: ComponentType.image, zIndex: 10),
          _text(
            id: 'locked-title',
            text: 'Quarterly update',
            zIndex: 20,
            isLocked: true,
          ),
          _shape(id: 'hidden-note', zIndex: -1, isVisible: false),
        ],
      ),
    );

    expect(
      service.filterLayers(layers, 'quarter').single.component.id,
      'locked-title',
    );
    expect(
      service.filterLayers(layers, 'image').single.component.id,
      'hero-image',
    );
    expect(
      service.filterLayers(layers, 'hidden').single.component.id,
      'hidden-note',
    );
    expect(
      service.filterLayers(layers, 'locked').single.component.id,
      'locked-title',
    );
  });

  test('custom layer names drive titles while content remains searchable', () {
    const service = ComponentLayerService();
    final layers = service.layersFor(
      Slide(
        id: 'slide',
        components: [
          _text(
            id: 'title',
            text: 'Quarterly update',
            zIndex: 10,
            layerName: 'Executive headline',
          ),
        ],
      ),
    );

    expect(layers.single.title, 'Executive headline');
    expect(
      service.filterLayers(layers, 'executive').single.component.id,
      'title',
    );
    expect(
      service.filterLayers(layers, 'quarterly').single.component.id,
      'title',
    );
  });

  test('layer navigation follows current layer order without wrapping', () {
    const service = ComponentLayerService();
    final layers = service.layersFor(
      Slide(
        id: 'slide',
        components: [
          _shape(id: 'background', zIndex: 0),
          _shape(id: 'image', type: ComponentType.image, zIndex: 20),
          _text(id: 'title', text: 'Quarterly update', zIndex: 30),
          _shape(id: 'badge', type: ComponentType.circle, zIndex: 30),
          _shape(id: 'hidden-note', zIndex: -1, isVisible: false),
        ],
      ),
    );

    expect(service.previousLayerId(layers, 'title'), 'badge');
    expect(service.nextLayerId(layers, 'title'), 'image');
    expect(service.previousLayerId(layers, 'badge'), isNull);
    expect(service.nextLayerId(layers, 'hidden-note'), isNull);
    expect(service.nextLayerId(layers, null), isNull);
  });

  test('filterLayers applies visibility and lock filters with counts', () {
    const service = ComponentLayerService();
    final layers = service.layersFor(
      Slide(
        id: 'slide',
        components: [
          _shape(id: 'background', zIndex: 0),
          _shape(id: 'hero-image', type: ComponentType.image, zIndex: 10),
          _text(
            id: 'locked-title',
            text: 'Quarterly update',
            zIndex: 20,
            isLocked: true,
          ),
          _text(
            id: 'hidden-note',
            text: 'Hidden cue',
            zIndex: -1,
            isVisible: false,
          ),
        ],
      ),
    );

    expect(
      service
          .filterLayers(layers, '', filter: ComponentLayerFilter.visible)
          .map((item) => item.component.id),
      ['locked-title', 'hero-image', 'background'],
    );
    expect(
      service
          .filterLayers(layers, '', filter: ComponentLayerFilter.hidden)
          .map((item) => item.component.id),
      ['hidden-note'],
    );
    expect(
      service
          .filterLayers(layers, '', filter: ComponentLayerFilter.locked)
          .map((item) => item.component.id),
      ['locked-title'],
    );

    expect(service.filterCounts(layers, ''), {
      ComponentLayerFilter.all: 4,
      ComponentLayerFilter.visible: 3,
      ComponentLayerFilter.hidden: 1,
      ComponentLayerFilter.locked: 1,
    });
    expect(service.filterCounts(layers, 'quarter'), {
      ComponentLayerFilter.all: 1,
      ComponentLayerFilter.visible: 1,
      ComponentLayerFilter.hidden: 0,
      ComponentLayerFilter.locked: 1,
    });
  });
}

PresentationComponent _shape({
  required String id,
  required int zIndex,
  ComponentType type = ComponentType.shape,
  bool isVisible = true,
}) {
  return PresentationComponent(
    id: id,
    type: type,
    position: Offset.zero,
    size: const Size(100, 80),
    zIndex: zIndex,
    isVisible: isVisible,
  );
}

PresentationComponent _text({
  required String id,
  required String text,
  required int zIndex,
  bool isLocked = false,
  bool isVisible = true,
  String? layerName,
}) {
  return PresentationComponent(
    id: id,
    type: ComponentType.richText,
    position: Offset.zero,
    size: const Size(200, 80),
    layerName: layerName,
    zIndex: zIndex,
    isLocked: isLocked,
    isVisible: isVisible,
    richText: RichTextContent(
      text: text,
      style: const TextStyle(color: Colors.white, fontSize: 24),
    ),
  );
}
