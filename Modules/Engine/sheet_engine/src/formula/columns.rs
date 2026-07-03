//! A1 column label conversion helpers.

pub(super) fn column_index(label: &str) -> Option<u32> {
    let mut value = 0u32;
    for ch in label.chars() {
        if !ch.is_ascii_alphabetic() {
            return None;
        }
        let digit = ch.to_ascii_uppercase() as u32 - 'A' as u32 + 1;
        value = value.checked_mul(26)?.checked_add(digit)?;
    }

    value.checked_sub(1)
}

pub(super) fn column_label(index: u32) -> String {
    let mut value = u64::from(index) + 1;
    let mut label = Vec::new();

    while value > 0 {
        let rem = (value - 1) % 26;
        label.push((b'A' + rem as u8) as char);
        value = (value - 1) / 26;
    }

    label.into_iter().rev().collect()
}
