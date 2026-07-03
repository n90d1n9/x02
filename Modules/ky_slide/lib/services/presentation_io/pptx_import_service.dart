import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:xml/xml.dart';

import '../../models/component.dart';
import '../../models/presentation.dart';
import '../../models/presentation_component.dart';
import '../../models/slide.dart';
import '../../models/style/presentation_theme.dart';
import 'pptx_geometry_mapper.dart';
import 'pptx_open_xml_utils.dart';
import 'pptx_opacity_mapper.dart';
import 'pptx_relationships.dart';
import 'pptx_shape_mapper.dart';
import 'pptx_slide_background.dart';
import 'pptx_slide_notes.dart';
import 'pptx_text_mapper.dart';

class PptxImportService {
  static const Size _defaultSlideSize = Size(1920, 1080);

  final PptxShapeMapper shapeMapper;
  final PptxRelationshipReader relationshipReader;
  final PptxSlideBackground slideBackground;
  final PptxSlideNotes slideNotes;
  final PptxTextMapper textMapper;
  final PptxGeometryMapper geometryMapper;
  final PptxOpacityMapper opacityMapper;

  const PptxImportService({
    this.shapeMapper = const PptxShapeMapper(),
    this.relationshipReader = const PptxRelationshipReader(),
    this.slideBackground = const PptxSlideBackground(),
    this.slideNotes = const PptxSlideNotes(),
    this.textMapper = const PptxTextMapper(),
    this.geometryMapper = const PptxGeometryMapper(),
    this.opacityMapper = const PptxOpacityMapper(),
  });

  Presentation importBytes(Uint8List bytes, {String? title}) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final presentationXml = _xmlFile(archive, 'ppt/presentation.xml');
    final relsXml = _xmlFile(archive, 'ppt/_rels/presentation.xml.rels');
    final slideSize = _slideSize(presentationXml);
    final slidePaths = _orderedSlidePaths(presentationXml, relsXml);

    if (slidePaths.isEmpty) {
      throw const PptxImportException('No slides were found in the PPTX file.');
    }

    final slides = slidePaths.indexed.map((entry) {
      final slideNumber = entry.$1 + 1;
      final slidePath = entry.$2;
      final slideXml = _xmlFile(archive, slidePath);
      final relationships = relationshipReader.forPart(archive, slidePath);
      return _slideFromXml(
        archive: archive,
        slideXml: slideXml,
        slidePath: slidePath,
        slideNumber: slideNumber,
        slideSize: slideSize,
        relationships: relationships,
      );
    }).toList();

    return Presentation(
      id: const Uuid().v4(),
      title: title?.trim().isNotEmpty == true ? title!.trim() : 'Imported PPTX',
      slides: slides,
      theme: _importTheme(),
      slideSize: slideSize,
    );
  }

  XmlDocument _xmlFile(Archive archive, String path) {
    final file = archive.findFile(path);
    if (file == null) {
      throw PptxImportException('Missing required PPTX part: $path');
    }

    return XmlDocument.parse(String.fromCharCodes(file.content));
  }

  Size _slideSize(XmlDocument presentationXml) {
    final sizeElement = _firstElement(presentationXml, 'sldSz');
    if (sizeElement == null) return _defaultSlideSize;

    final cx = int.tryParse(sizeElement.getAttribute('cx') ?? '');
    final cy = int.tryParse(sizeElement.getAttribute('cy') ?? '');
    if (cx == null || cy == null || cx <= 0 || cy <= 0) {
      return _defaultSlideSize;
    }

    return Size(_defaultSlideSize.width, _defaultSlideSize.width * cy / cx);
  }

  List<String> _orderedSlidePaths(
    XmlDocument presentationXml,
    XmlDocument relsXml,
  ) {
    final relationships = <String, String>{};
    for (final rel in _elements(relsXml, 'Relationship')) {
      final id = rel.getAttribute('Id');
      final target = rel.getAttribute('Target');
      if (id != null && target != null) {
        relationships[id] = target;
      }
    }

    final paths = <String>[];
    for (final slideId in _elements(presentationXml, 'sldId')) {
      final relationshipId = slideId.getAttribute('r:id');
      final target = relationships[relationshipId];
      if (target == null) continue;
      paths.add(target.startsWith('ppt/') ? target : 'ppt/$target');
    }

    return paths;
  }

  Slide _slideFromXml({
    required Archive archive,
    required XmlDocument slideXml,
    required String slidePath,
    required int slideNumber,
    required Size slideSize,
    required List<PptxPartRelationship> relationships,
  }) {
    final components = <PresentationComponent>[];
    final metrics = PptxSlideMetrics.fromSize(slideSize);
    final spTree = _firstElement(slideXml, 'spTree');
    final relationshipTargets = relationshipReader.targetsById(relationships);

    for (final element
        in spTree?.children.whereType<XmlElement>() ?? const <XmlElement>[]) {
      switch (element.name.local) {
        case 'sp':
          final component =
              _textComponentFromShape(
                element,
                metrics,
                zIndex: components.length,
              ) ??
              _shapeComponentFromShape(
                element,
                metrics,
                zIndex: components.length,
              );
          if (component != null) {
            components.add(component);
          }
          break;
        case 'pic':
          final component = _imageComponentFromPicture(
            archive: archive,
            picture: element,
            slidePath: slidePath,
            relationships: relationshipTargets,
            metrics: metrics,
            zIndex: components.length,
          );
          if (component != null) {
            components.add(component);
          }
          break;
        default:
          break;
      }
    }

    if (components.isEmpty) {
      for (final shape in _elements(slideXml, 'sp')) {
        final component =
            _textComponentFromShape(
              shape,
              metrics,
              zIndex: components.length,
            ) ??
            _shapeComponentFromShape(shape, metrics, zIndex: components.length);
        if (component != null) {
          components.add(component);
        }
      }
    }

    final firstTitle = components
        .where(
          (component) => component.richText?.text.trim().isNotEmpty == true,
        )
        .firstOrNull
        ?.richText
        ?.text
        .split('\n')
        .first;

    return Slide(
      id: const Uuid().v4(),
      title: firstTitle ?? 'Slide $slideNumber',
      backgroundColor: slideBackground.colorFromSlide(slideXml),
      notes: slideNotes.notesForSlide(archive, slidePath, relationships),
      components: components,
    );
  }

  PresentationComponent? _textComponentFromShape(
    XmlElement shape,
    PptxSlideMetrics metrics, {
    required int zIndex,
  }) {
    final richText = textMapper.contentFromShape(shape);
    if (richText == null) return null;

    final geometry = geometryMapper.fromElement(shape, metrics);
    return PresentationComponent(
      id: const Uuid().v4(),
      type: ComponentType.richText,
      position: geometry.position,
      size: geometry.size,
      richText: richText,
      layerName: _layerNameFromElement(shape),
      rotation: geometry.rotation,
      opacity: textMapper.opacityFromShape(shape),
      zIndex: zIndex,
    );
  }

  PresentationComponent? _shapeComponentFromShape(
    XmlElement shape,
    PptxSlideMetrics metrics, {
    required int zIndex,
  }) {
    final preset = _firstElement(shape, 'prstGeom')?.getAttribute('prst');
    final spec = shapeMapper.forPreset(preset);
    if (spec == null) return null;

    final fillColor = _shapeFillColor(shape);
    final border = _shapeBorder(shape);
    if (fillColor == null && border == null) return null;

    final geometry = geometryMapper.fromElement(shape, metrics);
    return PresentationComponent(
      id: const Uuid().v4(),
      type: spec.type,
      position: geometry.position,
      size: geometry.size,
      layerName: _layerNameFromElement(shape),
      backgroundColor: fillColor,
      border: border,
      rotation: geometry.rotation,
      opacity: opacityMapper.shapeOpacity(shape),
      zIndex: zIndex,
    );
  }

  PresentationComponent? _imageComponentFromPicture({
    required Archive archive,
    required XmlElement picture,
    required String slidePath,
    required Map<String, String> relationships,
    required PptxSlideMetrics metrics,
    required int zIndex,
  }) {
    final blip = _firstElement(picture, 'blip');
    final relationshipId =
        blip?.getAttribute('r:embed') ?? blip?.getAttribute('embed');
    final target = relationships[relationshipId];
    if (target == null) return null;

    final mediaPath = pptxResolvePartTarget(slidePath, target);
    final mediaFile = archive.findFile(mediaPath);
    if (mediaFile == null) return null;

    final geometry = geometryMapper.fromElement(picture, metrics);
    return PresentationComponent(
      id: const Uuid().v4(),
      type: ComponentType.image,
      position: geometry.position,
      size: geometry.size,
      layerName: _layerNameFromElement(picture),
      imageData: mediaFile.content,
      rotation: geometry.rotation,
      opacity: opacityMapper.pictureOpacity(picture),
      zIndex: zIndex,
    );
  }

  Color? _shapeFillColor(XmlElement shape) {
    final spPr = _firstElement(shape, 'spPr');
    final solidFill = spPr == null ? null : _firstElement(spPr, 'solidFill');
    final color = solidFill == null
        ? null
        : _firstElement(solidFill, 'srgbClr');

    return pptxColorFromHex(color?.getAttribute('val'));
  }

  BorderSide? _shapeBorder(XmlElement shape) {
    final spPr = _firstElement(shape, 'spPr');
    final line = spPr == null ? null : _firstElement(spPr, 'ln');
    if (line == null || _firstElement(line, 'noFill') != null) return null;

    final solidFill = _firstElement(line, 'solidFill');
    final color = solidFill == null
        ? null
        : _firstElement(solidFill, 'srgbClr');
    final borderColor = pptxColorFromHex(color?.getAttribute('val'));
    if (borderColor == null) return null;

    final widthEmu = int.tryParse(line.getAttribute('w') ?? '');
    return BorderSide(
      color: borderColor,
      width: widthEmu == null || widthEmu <= 0 ? 1 : widthEmu / 12700,
    );
  }

  XmlElement? _firstElement(XmlNode node, String localName) {
    return _elements(node, localName).firstOrNull;
  }

  Iterable<XmlElement> _elements(XmlNode node, String localName) {
    return node.descendants.whereType<XmlElement>().where(
      (element) => element.name.local == localName,
    );
  }

  String? _layerNameFromElement(XmlElement element) {
    final name = _firstElement(element, 'cNvPr')?.getAttribute('name')?.trim();
    if (name == null || name.isEmpty || _isGeneratedLayerName(name)) {
      return null;
    }

    return name;
  }

  bool _isGeneratedLayerName(String name) {
    return RegExp(
      r'^(Text|Picture|Rectangle|Ellipse|Triangle)\s+\d+$',
    ).hasMatch(name);
  }
}

PresentationTheme _importTheme() {
  return PresentationTheme(
    id: 'pptx_import',
    name: 'PPTX Import',
    primaryColor: const Color(0xFF2563EB),
    secondaryColor: const Color(0xFF14B8A6),
    backgroundColor: Colors.white,
    textColor: const Color(0xFF111827),
    titleStyle: const TextStyle(
      color: Color(0xFF111827),
      fontSize: 44,
      fontWeight: FontWeight.w700,
    ),
    bodyStyle: const TextStyle(color: Color(0xFF334155), fontSize: 22),
    colorPalette: const [
      Color(0xFF2563EB),
      Color(0xFF14B8A6),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
    ],
  );
}

class PptxImportException implements Exception {
  final String message;

  const PptxImportException(this.message);

  @override
  String toString() => message;
}
