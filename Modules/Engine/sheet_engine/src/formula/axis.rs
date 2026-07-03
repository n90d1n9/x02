//! Axis shifting helpers for formula reference rewrites.

pub(super) fn shift_inserted_axis(index: u32, insert_start: u32, count: u32) -> Option<u32> {
    if index >= insert_start {
        index.checked_add(count)
    } else {
        Some(index)
    }
}

pub(super) fn shift_deleted_axis(index: u32, delete_start: u32, count: u32) -> Option<u32> {
    let delete_end = delete_start.saturating_add(count);
    if index >= delete_start && index < delete_end {
        None
    } else if index >= delete_end {
        index.checked_sub(count)
    } else {
        Some(index)
    }
}

pub(super) fn translate_index(index: u32, delta: i64) -> Option<u32> {
    let translated = i64::from(index) + delta;
    if translated < 0 || translated > i64::from(u32::MAX) {
        None
    } else {
        Some(translated as u32)
    }
}
