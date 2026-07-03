use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct GridPosition {
    pub col: u32,
    pub row: u32,
}

impl GridPosition {
    pub fn new(col: u32, row: u32) -> Self {
        Self { col, row }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct GridRange {
    pub anchor: GridPosition,
    pub focus: GridPosition,
}

impl GridRange {
    pub fn new(anchor: GridPosition, focus: GridPosition) -> Self {
        Self { anchor, focus }
    }

    pub fn single(position: GridPosition) -> Self {
        Self::new(position, position)
    }

    pub fn top_left(self) -> GridPosition {
        GridPosition::new(
            self.anchor.col.min(self.focus.col),
            self.anchor.row.min(self.focus.row),
        )
    }

    pub fn bottom_right(self) -> GridPosition {
        GridPosition::new(
            self.anchor.col.max(self.focus.col),
            self.anchor.row.max(self.focus.row),
        )
    }

    pub fn width(self) -> u32 {
        self.bottom_right().col - self.top_left().col + 1
    }

    pub fn height(self) -> u32 {
        self.bottom_right().row - self.top_left().row + 1
    }

    pub fn cell_count(self) -> u64 {
        u64::from(self.width()) * u64::from(self.height())
    }

    pub fn contains(self, position: GridPosition) -> bool {
        let top_left = self.top_left();
        let bottom_right = self.bottom_right();

        position.col >= top_left.col
            && position.col <= bottom_right.col
            && position.row >= top_left.row
            && position.row <= bottom_right.row
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct GridSelection {
    pub active: GridPosition,
    pub ranges: Vec<GridRange>,
}

impl GridSelection {
    pub fn cell(active: GridPosition) -> Self {
        Self {
            active,
            ranges: vec![GridRange::single(active)],
        }
    }

    pub fn range(range: GridRange) -> Self {
        Self {
            active: range.focus,
            ranges: vec![range],
        }
    }

    pub fn new(active: GridPosition, ranges: Vec<GridRange>) -> Self {
        let ranges = if ranges.is_empty() {
            vec![GridRange::single(active)]
        } else {
            ranges
        };

        Self { active, ranges }
    }

    pub fn add_range(&mut self, range: GridRange) {
        self.active = range.focus;
        self.ranges.push(range);
    }

    pub fn range_count(&self) -> usize {
        self.ranges.len()
    }

    pub fn contains(&self, position: GridPosition) -> bool {
        self.ranges.iter().any(|range| range.contains(position))
    }
}
