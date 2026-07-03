use crate::{SheetEdit, SheetGrid, SHEET_ENGINE_ID};
use waraq_core::{DocumentId, OfficeDocumentSession};

pub type SheetSession = OfficeDocumentSession<SheetGrid, SheetEdit>;

pub fn sheet_session(document_id: impl Into<DocumentId>, grid: SheetGrid) -> SheetSession {
    OfficeDocumentSession::new(SHEET_ENGINE_ID, document_id, grid)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{sheet_operation, CellPosition, CellValue};
    use waraq_core::{GridPosition, GridSelection, OfficeSelection, Validatable};

    #[test]
    fn sheet_session_applies_operation_and_snapshots_grid() {
        let mut session = sheet_session("sheet-1", SheetGrid::new("Sheet 1"));
        session.set_selection(OfficeSelection::Grid(GridSelection::cell(
            GridPosition::new(0, 0),
        )));

        session
            .apply_operation(sheet_operation(
                "op-1",
                "sheet-1",
                "actor-1",
                1,
                10_000,
                SheetEdit::SetCell {
                    position: CellPosition::new(0, 0),
                    raw_content: "=1+2".into(),
                },
            ))
            .unwrap();

        let snapshot = session.snapshot(10_001);

        assert_eq!(
            session
                .state()
                .get_cell(&CellPosition::new(0, 0))
                .unwrap()
                .evaluated_value,
            CellValue::Number(3.0)
        );
        assert_eq!(
            snapshot.selection,
            OfficeSelection::Grid(GridSelection::cell(GridPosition::new(0, 0)))
        );
        assert_eq!(snapshot.state.cell_count(), 1);
        assert_eq!(snapshot.operation_log.len(), 1);
        assert!(snapshot.validate_report().is_valid());
    }
}
