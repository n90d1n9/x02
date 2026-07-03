import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import '../../models/slide.dart';
import 'pptx_open_xml_utils.dart';
import 'pptx_relationships.dart';

class PptxSlideNotes {
  const PptxSlideNotes();

  bool hasNotes(Slide slide) => (slide.notes ?? '').trim().isNotEmpty;

  String notesSlideXml(Slide slide, int slideNumber) {
    final noteText = pptxXmlText((slide.notes ?? '').trim());

    return '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:notes xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
  <p:cSld name="Notes $slideNumber">
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
      <p:sp>
        <p:nvSpPr>
          <p:cNvPr id="2" name="Notes"/>
          <p:cNvSpPr txBox="1"/>
          <p:nvPr/>
        </p:nvSpPr>
        <p:spPr>
          <a:xfrm>
            <a:off x="914400" y="4572000"/>
            <a:ext cx="7315200" cy="2743200"/>
          </a:xfrm>
          <a:prstGeom prst="rect"><a:avLst/></a:prstGeom>
          <a:noFill/>
          <a:ln><a:noFill/></a:ln>
        </p:spPr>
        <p:txBody>
          <a:bodyPr wrap="square"/>
          <a:lstStyle/>
          <a:p>
            <a:r>
              <a:rPr lang="en-US" sz="1800"/>
              <a:t>$noteText</a:t>
            </a:r>
          </a:p>
        </p:txBody>
      </p:sp>
    </p:spTree>
  </p:cSld>
  <p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr>
</p:notes>''';
  }

  String notesRelationshipsXml(int slideNumber) {
    return '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="../slides/slide$slideNumber.xml"/>
</Relationships>''';
  }

  String? notesForSlide(
    Archive archive,
    String slidePath,
    List<PptxPartRelationship> relationships,
  ) {
    final notesRelationship = relationships
        .where((relationship) => relationship.isNotesSlide)
        .firstOrNull;
    if (notesRelationship == null) return null;

    final notesPath = pptxResolvePartTarget(
      slidePath,
      notesRelationship.target,
    );
    final notesFile = archive.findFile(notesPath);
    if (notesFile == null) return null;

    final notesXml = XmlDocument.parse(String.fromCharCodes(notesFile.content));
    final notes = notesXml.descendants
        .whereType<XmlElement>()
        .where((element) => element.name.local == 't')
        .map((element) => element.innerText.trim())
        .where((text) => text.isNotEmpty)
        .join('\n')
        .trim();

    return notes.isEmpty ? null : notes;
  }
}
