


// ─────────────────────────────────────────────────────────────────────────────
// Bookmarks
// ─────────────────────────────────────────────────────────────────────────────

pub fn extract_bookmarks(doc: &Document) -> Result<Vec<BookmarkNode>> {
    let cat_id = doc
        .trailer
        .get(b"Root")
        .and_then(|o| o.as_reference())
        .map_err(|e| Error::Parse(e.to_string()))?;
    let catalog = doc.get_object(cat_id)?;
    let dict = catalog.as_dict().map_err(|e| Error::Parse(e.to_string()))?;
    let outlines_ref = match dict.get(b"Outlines") {
        Ok(Object::Reference(id)) => *id,
        _ => return Ok(vec![]),
    };
    let outlines_obj = doc.get_object(outlines_ref)?;
    let outlines_dict = outlines_obj
        .as_dict()
        .map_err(|e| Error::Parse(e.to_string()))?;
    let first = match outlines_dict.get(b"First") {
        Ok(Object::Reference(id)) => *id,
        _ => return Ok(vec![]),
    };
    Ok(walk_outline(doc, first, 0))
}

fn walk_outline(doc: &Document, item_id: ObjectId, level: usize) -> Vec<BookmarkNode> {
    let mut nodes = Vec::new();
    let mut current = Some(item_id);
    while let Some(id) = current {
        let obj = match doc.get_object(id) {
            Ok(o) => o,
            Err(_) => break,
        };
        let dict = match obj.as_dict() {
            Ok(d) => d,
            Err(_) => break,
        };
        let title = get_str(dict, b"Title").unwrap_or_default();
        let page_index = resolve_dest_page(doc, dict);
        let children = match dict.get(b"First") {
            Ok(Object::Reference(cid)) => walk_outline(doc, *cid, level + 1),
            _ => vec![],
        };
        nodes.push(BookmarkNode {
            title,
            page_index,
            level,
            children,
        });
        current = match dict.get(b"Next") {
            Ok(Object::Reference(nid)) => Some(*nid),
            _ => None,
        };
    }
    nodes
}

fn resolve_dest_page(doc: &Document, dict: &lopdf::Dictionary) -> Option<usize> {
    let dest = dict.get(b"Dest").ok()?;
    let array = match dest {
        Object::Array(a) => a,
        Object::Reference(id) => {
            let obj = doc.get_object(*id).ok()?;
            return if let Object::Array(a) = obj {
                page_from_dest_array(doc, a)
            } else {
                None
            };
        }
        _ => return None,
    };
    page_from_dest_array(doc, array)
}

fn page_from_dest_array(doc: &Document, array: &[Object]) -> Option<usize> {
    if let Some(Object::Reference(page_id)) = array.first() {
        for (num, id) in &doc.get_pages() {
            if id == page_id {
                return Some((*num as usize).saturating_sub(1));
            }
        }
    }
    None
}
