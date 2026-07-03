import 'dart:convert';

import 'package:archive/archive.dart';

import '../../models/component.dart';
import '../../models/presentation.dart';
import '../../models/presentation_component.dart';
import '../../models/slide.dart';
import 'pptx_component_ordering.dart';
import 'pptx_geometry_mapper.dart';
import 'pptx_open_xml_utils.dart';
import 'pptx_opacity_mapper.dart';
import 'pptx_package_xml.dart';
import 'pptx_shape_mapper.dart';
import 'pptx_slide_background.dart';
import 'pptx_slide_media.dart';
import 'pptx_slide_notes.dart';
import 'pptx_text_mapper.dart';

class PptxExportService {
  final PptxPackageXml packageXml;
  final PptxSlideMediaCollector mediaCollector;
  final PptxShapeMapper shapeMapper;
  final PptxSlideBackground slideBackground;
  final PptxSlideNotes slideNotes;
  final PptxTextMapper textMapper;
  final PptxGeometryMapper geometryMapper;
  final PptxComponentOrdering componentOrdering;
  final PptxOpacityMapper opacityMapper;

  const PptxExportService({
    this.packageXml = const PptxPackageXml(),
    this.mediaCollector = const PptxSlideMediaCollector(),
    this.shapeMapper = const PptxShapeMapper(),
    this.slideBackground = const PptxSlideBackground(),
    this.slideNotes = const PptxSlideNotes(),
    this.textMapper = const PptxTextMapper(),
    this.geometryMapper = const PptxGeometryMapper(),
    this.componentOrdering = const PptxComponentOrdering(),
    this.opacityMapper = const PptxOpacityMapper(),
  });

  List<int> exportBytes(Presentation presentation) {
    final archive = Archive();
    final metrics = PptxSlideMetrics.fromPresentation(presentation);
    var nextMediaIndex = 1;

    // archive 3.x: ArchiveFile(name, size, content) — no named constructors.
    void addXml(String path, String content) {
      final bytes = utf8.encode(content);
      archive.addFile(ArchiveFile(path, bytes.length, bytes));
    }

    void addBytes(String path, List<int> bytes) {
      archive.addFile(ArchiveFile(path, bytes.length, bytes));
    }

    addXml('[Content_Types].xml', packageXml.contentTypes(presentation));
    addXml('_rels/.rels', packageXml.packageRelationships());
    addXml('docProps/app.xml', packageXml.appProperties(presentation));
    addXml('docProps/core.xml', packageXml.coreProperties(presentation));
    addXml(
      'ppt/presentation.xml',
      packageXml.presentation(presentation, metrics.slideCy),
    );
    addXml(
      'ppt/_rels/presentation.xml.rels',
      packageXml.presentationRelationships(presentation),
    );
    addXml('ppt/theme/theme1.xml', packageXml.theme());
    addXml('ppt/slideMasters/slideMaster1.xml', packageXml.slideMaster());
    addXml(
      'ppt/slideMasters/_rels/slideMaster1.xml.rels',
      packageXml.slideMasterRelationships(),
    );
    addXml('ppt/slideLayouts/slideLayout1.xml', packageXml.slideLayout());
    addXml(
      'ppt/slideLayouts/_rels/slideLayout1.xml.rels',
      packageXml.slideLayoutRelationships(),
    );

    for (final (index, slide) in presentation.slides.indexed) {
      final slideNumber = index + 1;
      final slideMedia = mediaCollector.collect(
        slide,
        firstRelationshipNumber: 2,
        firstMediaIndex: nextMediaIndex,
      );
      final notesRelationshipId = slideNotes.hasNotes(slide)
          ? 'rId${slideMedia.length + 2}'
          : null;
      nextMediaIndex += slideMedia.length;

      for (final image in slideMedia) {
        addBytes('ppt/media/${image.fileName}', image.bytes);
      }

      addXml(
        'ppt/slides/slide$slideNumber.xml',
        _slideXml(
          slide: slide,
          slideNumber: slideNumber,
          metrics: metrics,
          slideMedia: slideMedia,
        ),
      );
      addXml(
        'ppt/slides/_rels/slide$slideNumber.xml.rels',
        _slideRelationshipsXml(
          slideMedia,
          notesRelationshipId: notesRelationshipId,
          slideNumber: slideNumber,
        ),
      );

      if (notesRelationshipId != null) {
        addXml(
          'ppt/notesSlides/notesSlide$slideNumber.xml',
          slideNotes.notesSlideXml(slide, slideNumber),
        );
        addXml(
          'ppt/notesSlides/_rels/notesSlide$slideNumber.xml.rels',
          slideNotes.notesRelationshipsXml(slideNumber),
        );
      }
    }

    return ZipEncoder().encode(archive) ?? const [];
  }

  String _slideXml({
    required Slide slide,
    required int slideNumber,
    required PptxSlideMetrics metrics,
    required List<PptxSlideMedia> slideMedia,
  }) {
    final imagesByComponentId = {
      for (final image in slideMedia) image.component.id: image,
    };
    final componentXml = StringBuffer();
    var shapeId = 2;

    for (final component in componentOrdering.orderedComponents(slide)) {
      switch (component.type) {
        case ComponentType.richText:
          final xml = _textShapeXml(
            component: component,
            shapeId: shapeId,
            metrics: metrics,
          );
          if (xml.isNotEmpty) {
            componentXml.write(xml);
            shapeId++;
          }
          break;
        case ComponentType.image:
          final image = imagesByComponentId[component.id];
          if (image != null) {
            componentXml.write(
              _pictureXml(
                component: component,
                shapeId: shapeId,
                image: image,
                metrics: metrics,
              ),
            );
            shapeId++;
          }
          break;
        case ComponentType.shape:
        case ComponentType.circle:
        case ComponentType.triangle:
          final xml = _shapeXml(
            component: component,
            shapeId: shapeId,
            metrics: metrics,
          );
          if (xml.isNotEmpty) {
            componentXml.write(xml);
            shapeId++;
          }
          break;
        default:
          break;
      }
    }

    final title = pptxXmlAttr(slide.title ?? 'Slide $slideNumber');
    final backgroundXml = slideBackground.xmlFor(slide.backgroundColor);

    return '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
  <p:cSld name="$title">
    $backgroundXml
    <p:spTree>
      <p:nvGrpSpPr>
        <p:cNvPr id="1" name=""/>
        <p:cNvGrpSpPr/>
        <p:nvPr/>
      </p:nvGrpSpPr>
      <p:grpSpPr>
        <a:xfrm>
          <a:off x="0" y="0"/>
          <a:ext cx="0" cy="0"/>
          <a:chOff x="0" y="0"/>
          <a:chExt cx="0" cy="0"/>
        </a:xfrm>
      </p:grpSpPr>
      $componentXml
    </p:spTree>
  </p:cSld>
  <p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr>
</p:sld>''';
  }

  String _textShapeXml({
    required PresentationComponent component,
    required int shapeId,
    required PptxSlideMetrics metrics,
  }) {
    final richText = component.richText;
    if (richText == null || richText.text.trim().isEmpty) {
      return '';
    }

    final textBodyXml = textMapper.textBodyXml(
      richText,
      opacity: component.opacity,
    );
    final transformXml = geometryMapper.transformXml(component, metrics);
    final shapeName = _componentName(component, 'Text $shapeId');

    return '''
<p:sp>
  <p:nvSpPr>
    <p:cNvPr id="$shapeId" name="$shapeName"/>
    <p:cNvSpPr txBox="1"/>
    <p:nvPr/>
  </p:nvSpPr>
  <p:spPr>
    $transformXml
    <a:prstGeom prst="rect"><a:avLst/></a:prstGeom>
    <a:noFill/>
    <a:ln><a:noFill/></a:ln>
  </p:spPr>
  $textBodyXml
</p:sp>''';
  }

  String _pictureXml({
    required PresentationComponent component,
    required int shapeId,
    required PptxSlideMedia image,
    required PptxSlideMetrics metrics,
  }) {
    final transformXml = geometryMapper.transformXml(component, metrics);
    final alphaModFixXml = opacityMapper.alphaModFixXml(component.opacity);
    final blipXml = alphaModFixXml.isEmpty
        ? '<a:blip r:embed="${image.relationshipId}"/>'
        : '<a:blip r:embed="${image.relationshipId}">$alphaModFixXml</a:blip>';
    final pictureName = _componentName(component, 'Picture $shapeId');

    return '''
<p:pic>
  <p:nvPicPr>
    <p:cNvPr id="$shapeId" name="$pictureName"/>
    <p:cNvPicPr><a:picLocks noChangeAspect="1"/></p:cNvPicPr>
    <p:nvPr/>
  </p:nvPicPr>
  <p:blipFill>
    $blipXml
    <a:stretch><a:fillRect/></a:stretch>
  </p:blipFill>
  <p:spPr>
    $transformXml
    <a:prstGeom prst="rect"><a:avLst/></a:prstGeom>
  </p:spPr>
</p:pic>''';
  }

  String _shapeXml({
    required PresentationComponent component,
    required int shapeId,
    required PptxSlideMetrics metrics,
  }) {
    final spec = shapeMapper.forComponent(component.type);
    if (spec == null) return '';

    final fillXml = shapeMapper.fillXml(
      component.backgroundColor,
      opacity: component.opacity,
    );
    final lineXml = shapeMapper.lineXml(
      component.border,
      opacity: component.opacity,
    );
    final transformXml = geometryMapper.transformXml(component, metrics);
    final shapeName = _componentName(component, '${spec.name} $shapeId');

    return '''
<p:sp>
  <p:nvSpPr>
    <p:cNvPr id="$shapeId" name="$shapeName"/>
    <p:cNvSpPr/>
    <p:nvPr/>
  </p:nvSpPr>
  <p:spPr>
    $transformXml
    <a:prstGeom prst="${spec.preset}"><a:avLst/></a:prstGeom>
    $fillXml
    $lineXml
  </p:spPr>
</p:sp>''';
  }

  String _slideRelationshipsXml(
    List<PptxSlideMedia> slideMedia, {
    required String? notesRelationshipId,
    required int slideNumber,
  }) {
    final imageRelationships = slideMedia.map((image) {
      return '<Relationship Id="${image.relationshipId}" '
          'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" '
          'Target="../media/${image.fileName}"/>';
    }).join();
    final notesRelationship = notesRelationshipId == null
        ? ''
        : '<Relationship Id="$notesRelationshipId" '
              'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/notesSlide" '
              'Target="../notesSlides/notesSlide$slideNumber.xml"/>';

    return '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>
  $imageRelationships
  $notesRelationship
</Relationships>''';
  }

  String _componentName(PresentationComponent component, String fallback) {
    final name = component.layerName?.trim();
    return pptxXmlAttr(name == null || name.isEmpty ? fallback : name);
  }
}
