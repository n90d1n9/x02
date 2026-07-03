use docx_reader::DocxReader;
use std::path::Path;

#[test]
fn test_sample_docx_parts() {
    let path = "../Sample/sample02-complete.docx"; // relative to project root
    if !Path::new(path).exists() {
        return;
    }

    let reader = DocxReader::open(path).expect("Failed to open sample docx");
    let parts = reader.part_names().expect("Failed to list parts");
    // Expected parts from the sample (partial list)
    let expected = vec![
        "[Content_Types].xml",
        "_rels/.rels",
        "word/_rels/document.xml.rels",
        "word/document.xml",
        "word/styles.xml",
        "word/footnotes.xml",
        "word/footer1.xml",
        "word/header1.xml",
        "word/charts/chart1.xml",
        "word/media/image1.emf",
        "word/embeddings/Microsoft_Excel_Worksheet.xlsx",
        "word/diagrams/data1.xml",
    ];
    for exp in expected {
        assert!(parts.iter().any(|p| p == exp), "Missing part: {}", exp);
    }
}
