//! Defined names and named ranges from `xl/workbook.xml`.

use crate::cell::CellAddress;

#[cfg(feature = "serde-support")]
use serde::{Deserialize, Serialize};

/// Scope of a defined name.
#[derive(Debug, Clone, PartialEq, Eq)]
#[cfg_attr(feature = "serde-support", derive(Serialize, Deserialize))]
pub enum NameScope {
    /// Visible across the whole workbook.
    Workbook,
    /// Local to a specific sheet (zero-based sheet index).
    Sheet(usize),
}

/// A defined name / named range.
#[derive(Debug, Clone)]
#[cfg_attr(feature = "serde-support", derive(Serialize, Deserialize))]
pub struct DefinedName {
    /// The name (e.g. `"SalesData"`, `"_xlnm.Print_Area"`).
    pub name: String,
    /// The formula/reference (e.g. `"Sheet1!$A$1:$D$100"`).
    pub formula: String,
    /// Comment / description.
    pub comment: Option<String>,
    /// Scope.
    pub scope: NameScope,
    /// Whether this is a built-in name (starts with `"_xlnm."`).
    pub is_builtin: bool,
    /// Whether the name is hidden.
    pub hidden: bool,
}

impl DefinedName {
    /// Construct from raw parts.
    pub fn new(name: &str, formula: &str, local_sheet_id: Option<usize>) -> Self {
        Self {
            is_builtin: name.starts_with("_xlnm."),
            name: name.to_owned(),
            formula: formula.to_owned(),
            comment: None,
            scope: match local_sheet_id {
                Some(id) => NameScope::Sheet(id),
                None => NameScope::Workbook,
            },
            hidden: false,
        }
    }

    /// Try to resolve this name to a simple `SheetName!$A$1:$Z$99` range.
    /// Returns `(sheet_name, start, end)` if parseable.
    pub fn resolve_range(&self) -> Option<(String, CellAddress, CellAddress)> {
        // Strip leading = if present
        let formula = self.formula.trim_start_matches('=');
        // Handle Sheet1!$A$1:$D$10
        let (sheet, range) = formula.split_once('!')?;
        let sheet = sheet.trim_matches('\'').to_owned();
        let (start_str, end_str) = range.split_once(':')?;
        let start = CellAddress::from_a1(start_str.replace('$', "").as_str()).ok()?;
        let end = CellAddress::from_a1(end_str.replace('$', "").as_str()).ok()?;
        Some((sheet, start, end))
    }
}

/// Parse `<definedNames>` section from workbook.xml content.
#[allow(dead_code)]
pub(crate) fn parse_defined_names(xml: &str) -> Vec<DefinedName> {
    use quick_xml::events::Event;
    use quick_xml::Reader;

    let mut reader = Reader::from_str(xml);
    reader.trim_text(true);
    let mut buf = Vec::new();
    let mut names: Vec<DefinedName> = Vec::new();
    let mut current_name: Option<String> = None;
    let mut current_local: Option<usize> = None;
    let mut current_comment: Option<String> = None;
    let mut current_hidden = false;

    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Start(ref e)) if e.name().as_ref() == b"definedName" => {
                let mut name_str = String::new();
                let mut local = None;
                let mut comment = None;
                let mut hidden = false;

                for a in e.attributes().filter_map(|a| a.ok()) {
                    match a.key.as_ref() {
                        b"name" => name_str = String::from_utf8_lossy(&a.value).into_owned(),
                        b"localSheetId" => local = String::from_utf8_lossy(&a.value).parse().ok(),
                        b"comment" => {
                            comment = Some(String::from_utf8_lossy(&a.value).into_owned())
                        }
                        b"hidden" => hidden = a.value.as_ref() == b"1",
                        _ => {}
                    }
                }
                current_name = Some(name_str);
                current_local = local;
                current_comment = comment;
                current_hidden = hidden;
            }
            Ok(Event::Text(ref t)) if current_name.is_some() => {
                if let Ok(text) = t.unescape() {
                    let name = current_name.take().unwrap();
                    let mut dn = DefinedName::new(&name, &text, current_local);
                    dn.comment = current_comment.take();
                    dn.hidden = current_hidden;
                    names.push(dn);
                }
            }
            Ok(Event::End(ref e)) if e.name().as_ref() == b"definedName" => {
                current_name = None;
            }
            Ok(Event::Eof) | Err(_) => break,
            _ => {}
        }
        buf.clear();
    }

    names
}
