use super::*;
use crate::{ObjectId, Range};

#[test]
fn text_selection_normalizes_range_and_tracks_direction() {
    let forward = TextSelection::new(2, 8);
    assert_eq!(forward.range(), Range::new(2, 8));
    assert_eq!(forward.direction(), SelectionDirection::Forward);
    assert_eq!(forward.len(), 6);

    let backward = TextSelection::new(8, 2);
    assert_eq!(backward.range(), Range::new(2, 8));
    assert_eq!(backward.direction(), SelectionDirection::Backward);

    let caret = TextSelection::caret(4);
    assert!(caret.is_collapsed());
    assert_eq!(caret.direction(), SelectionDirection::Collapsed);
}

#[test]
fn grid_range_normalizes_drag_direction() {
    let range = GridRange::new(GridPosition::new(4, 5), GridPosition::new(2, 1));

    assert_eq!(range.top_left(), GridPosition::new(2, 1));
    assert_eq!(range.bottom_right(), GridPosition::new(4, 5));
    assert_eq!(range.width(), 3);
    assert_eq!(range.height(), 5);
    assert_eq!(range.cell_count(), 15);
    assert!(range.contains(GridPosition::new(3, 3)));
    assert!(!range.contains(GridPosition::new(5, 3)));
}

#[test]
fn grid_selection_supports_multiple_ranges() {
    let mut selection = GridSelection::cell(GridPosition::new(0, 0));
    selection.add_range(GridRange::new(
        GridPosition::new(2, 2),
        GridPosition::new(3, 3),
    ));

    assert_eq!(selection.range_count(), 2);
    assert_eq!(selection.active, GridPosition::new(3, 3));
    assert!(selection.contains(GridPosition::new(0, 0)));
    assert!(selection.contains(GridPosition::new(2, 3)));
}

#[test]
fn object_selection_dedupes_and_promotes_primary_after_remove() {
    let mut selection = ObjectSelection::single("shape-1");
    selection.add("shape-2");
    selection.add("shape-2");

    assert_eq!(selection.len(), 2);
    assert_eq!(selection.primary, Some(ObjectId::new("shape-1")));
    assert!(selection.contains(&ObjectId::new("shape-2")));

    assert!(selection.remove(&ObjectId::new("shape-1")));
    assert_eq!(selection.primary, Some(ObjectId::new("shape-2")));
}

#[test]
fn page_selection_keeps_unique_sorted_indices_with_active_page() {
    let mut selection = PageSelection::new(2, vec![4, 2, 4]);
    selection.add(1);

    assert_eq!(selection.page_indices, vec![1, 2, 4]);
    assert_eq!(selection.active, 1);
    assert!(selection.contains(4));
}

#[test]
fn office_selection_serializes_selected_variant() {
    let selection = OfficeSelection::Grid(GridSelection::range(GridRange::new(
        GridPosition::new(1, 1),
        GridPosition::new(2, 2),
    )));

    let json = serde_json::to_string(&selection).unwrap();
    let restored: OfficeSelection = serde_json::from_str(&json).unwrap();

    assert_eq!(restored, selection);
    assert!(!restored.is_empty());
}
