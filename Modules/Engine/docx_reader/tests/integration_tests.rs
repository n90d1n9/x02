use std::io::Write;
use docx_reader::{DocxReader, Block, TextOptions};

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Create a minimal but valid DOCX zip in memory containing one paragraph.
fn make_minimal_docx(paragraph_text: &str) -> Vec<u8> {
    use std::io::Cursor;

    let mut buf = Cursor::new(Vec::<u8>::new());
    {
        let mut zip = zip::ZipWriter::new(&mut buf);
        let opts = zip::write::FileOptions::default()
            .compression_method(zip::CompressionMethod::Stored);

        // [Content_Types].xml
        zip.start_file("[Content_Types].xml", opts).unwrap();
        zip.write_all(br#"<?xml version="1.0" encoding="UTF-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml"  ContentType="application/xml"/>
  <Override PartName="/word/document.xml"
            ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/docProps/core.xml"
            ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
</Types>"#).unwrap();

        // _rels/.rels
        zip.start_file("_rels/.rels", opts).unwrap();
        zip.write_all(br#"<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1"
    Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument"
    Target="word/document.xml"/>
  <Relationship Id="rId2"
    Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties"
    Target="docProps/core.xml"/>
</Relationships>"#).unwrap();

        // word/_rels/document.xml.rels
        zip.start_file("word/_rels/document.xml.rels", opts).unwrap();
        zip.write_all(br#"<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
</Relationships>"#).unwrap();

        // word/document.xml
        let doc_xml = format!(
            r#"<?xml version="1.0" encoding="UTF-8"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p>
      <w:r>
        <w:t>{}</w:t>
      </w:r>
    </w:p>
  </w:body>
</w:document>"#,
            paragraph_text
        );
        zip.start_file("word/document.xml", opts).unwrap();
        zip.write_all(doc_xml.as_bytes()).unwrap();

        // docProps/core.xml
        zip.start_file("docProps/core.xml", opts).unwrap();
        zip.write_all(br#"<?xml version="1.0" encoding="UTF-8"?>
<cp:coreProperties
  xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties"
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:dcterms="http://purl.org/dc/terms/"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <dc:title>Test Document</dc:title>
  <dc:creator>Test Author</dc:creator>
  <cp:revision>3</cp:revision>
</cp:coreProperties>"#).unwrap();

        zip.finish().unwrap();
    }
    buf.into_inner()
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

#[test]
fn test_from_bytes_valid() {
    let bytes = make_minimal_docx("Hello, World!");
    let reader = DocxReader::from_bytes(bytes);
    assert!(reader.is_ok(), "should accept valid DOCX bytes");
}

#[test]
fn test_from_bytes_invalid() {
    let bad = b"not a zip".to_vec();
    let reader = DocxReader::from_bytes(bad);
    assert!(reader.is_err(), "should reject non-ZIP bytes");
}

#[test]
fn test_extract_text() {
    let bytes = make_minimal_docx("Hello, docx_reader!");
    let reader = DocxReader::from_bytes(bytes).unwrap();
    let text = reader.extract_text().unwrap();
    assert!(text.contains("Hello, docx_reader!"), "extracted text should contain paragraph text");
}

#[test]
fn test_metadata_title_and_author() {
    let bytes = make_minimal_docx("irrelevant");
    let reader = DocxReader::from_bytes(bytes).unwrap();
    let meta = reader.metadata().unwrap();
    assert_eq!(meta.title.as_deref(), Some("Test Document"));
    assert_eq!(meta.creator.as_deref(), Some("Test Author"));
    assert_eq!(meta.revision, Some(3));
}

#[test]
fn test_parse_returns_document() {
    let bytes = make_minimal_docx("Paragraph text");
    let reader = DocxReader::from_bytes(bytes).unwrap();
    let doc = reader.parse().unwrap();
    assert!(!doc.body.is_empty(), "body should have at least one block");
    if let Some(docx_reader::Block::Paragraph(p)) = doc.body.first() {
        assert!(p.text().contains("Paragraph text"));
    } else {
        panic!("first block should be a Paragraph");
    }
}

#[test]
fn test_word_count() {
    let bytes = make_minimal_docx("one two three four five");
    let reader = DocxReader::from_bytes(bytes).unwrap();
    let count = reader.word_count().unwrap();
    assert_eq!(count, 5);
}

#[test]
fn test_char_count() {
    let bytes = make_minimal_docx("hello");
    let reader = DocxReader::from_bytes(bytes).unwrap();
    let count = reader.char_count().unwrap();
    // "hello\n" = 6 chars
    assert!(count >= 5);
}

#[test]
fn test_images_empty_on_minimal_docx() {
    let bytes = make_minimal_docx("no images");
    let reader = DocxReader::from_bytes(bytes).unwrap();
    let images = reader.images().unwrap();
    assert!(images.is_empty());
}

#[test]
fn test_comments_empty_on_minimal_docx() {
    let bytes = make_minimal_docx("no comments");
    let reader = DocxReader::from_bytes(bytes).unwrap();
    let comments = reader.comments().unwrap();
    assert!(comments.is_empty());
}

#[test]
fn test_footnotes_empty_on_minimal_docx() {
    let bytes = make_minimal_docx("no footnotes");
    let reader = DocxReader::from_bytes(bytes).unwrap();
    let fns = reader.footnotes().unwrap();
    assert!(fns.is_empty());
}

#[test]
fn test_to_json() {
    let bytes = make_minimal_docx("json test");
    let reader = DocxReader::from_bytes(bytes).unwrap();
    let json = reader.to_json().unwrap();
    assert!(json.contains("\"body\""));
    assert!(json.contains("json test"));
}

#[test]
fn test_text_options_separators() {
    let bytes = make_minimal_docx("sep test");
    let reader = DocxReader::from_bytes(bytes).unwrap();
    let opts = TextOptions {
        paragraph_separator: "||".to_string(),
        ..Default::default()
    };
    let text = reader.extract_text_with_options(&opts).unwrap();
    assert!(text.contains("sep test"));
}

#[test]
fn test_part_names_includes_document() {
    let bytes = make_minimal_docx("parts test");
    let reader = DocxReader::from_bytes(bytes).unwrap();
    let names = reader.part_names().unwrap();
    assert!(names.iter().any(|n| n.contains("document.xml")));
}

#[test]
fn test_raw_document_xml() {
    let bytes = make_minimal_docx("raw xml");
    let reader = DocxReader::from_bytes(bytes).unwrap();
    let xml = reader.raw_document_xml().unwrap();
    assert!(xml.contains("raw xml"));
}

#[test]
fn test_headings_empty_on_plain_para() {
    let bytes = make_minimal_docx("not a heading");
    let reader = DocxReader::from_bytes(bytes).unwrap();
    let headings = reader.headings(None).unwrap();
    assert!(headings.is_empty(), "plain paragraph should not be a heading");
}
