//! Validation rules for workbook-level XLSX snapshots.

use std::collections::BTreeSet;

use crate::XlsxWorkbookSnapshot;
use waraq_core::{Validatable, ValidationIssue, ValidationReport};

impl Validatable for XlsxWorkbookSnapshot {
    fn validate_report(&self) -> ValidationReport {
        let mut report = ValidationReport::new();

        if self.workbook_id().trim().is_empty() {
            report.push(
                ValidationIssue::error(
                    "xlsx.snapshot.workbook.empty",
                    "Workbook snapshot id is required",
                )
                .with_path("workbook_id"),
            );
        }

        if self.sheets().is_empty() {
            report.push(
                ValidationIssue::error(
                    "xlsx.snapshot.sheets.empty",
                    "Workbook snapshot must contain at least one sheet",
                )
                .with_path("sheets"),
            );
        }

        let mut sheet_names = BTreeSet::new();
        let mut document_ids = BTreeSet::new();
        for (index, sheet) in self.sheets().iter().enumerate() {
            let path = format!("sheets[{index}]");
            let sheet_name = sheet.sheet_name().trim();

            if sheet_name.is_empty() {
                report.push(
                    ValidationIssue::error(
                        "xlsx.snapshot.sheet_name.empty",
                        "Sheet snapshot name is required",
                    )
                    .with_path(format!("{path}.sheet_name")),
                );
            } else if !sheet_names.insert(sheet_name.to_owned()) {
                report.push(
                    ValidationIssue::error(
                        "xlsx.snapshot.sheet_name.duplicate",
                        format!("Sheet snapshot name `{sheet_name}` is duplicated"),
                    )
                    .with_path(format!("{path}.sheet_name")),
                );
            }

            if sheet.state_sheet_name().trim() != sheet_name {
                report.push(
                    ValidationIssue::error(
                        "xlsx.snapshot.sheet_state_name.mismatch",
                        format!(
                            "Sheet snapshot state name `{}` does not match workbook sheet `{sheet_name}`",
                            sheet.state_sheet_name()
                        ),
                    )
                    .with_path(format!("{path}.snapshot.state.name")),
                );
            }

            let document_id = sheet.document_id().as_str().trim();
            if !document_id.is_empty() && !document_ids.insert(document_id.to_owned()) {
                report.push(
                    ValidationIssue::error(
                        "xlsx.snapshot.document_id.duplicate",
                        format!("Sheet document id `{document_id}` is duplicated"),
                    )
                    .with_path(format!("{path}.snapshot.document_id")),
                );
            }

            report.extend_with_prefix(
                sheet.snapshot().validate_report(),
                format!("{path}.snapshot"),
            );
        }

        let active_sheet_name = self.active_sheet_name().trim();
        if active_sheet_name.is_empty() {
            report.push(
                ValidationIssue::error(
                    "xlsx.snapshot.active_sheet.empty",
                    "Workbook snapshot active sheet is required",
                )
                .with_path("active_sheet_name"),
            );
        } else if !sheet_names.contains(active_sheet_name) {
            report.push(
                ValidationIssue::error(
                    "xlsx.snapshot.active_sheet.unknown",
                    format!("Active sheet `{active_sheet_name}` is not present in sheets"),
                )
                .with_path("active_sheet_name"),
            );
        }

        report
    }
}
