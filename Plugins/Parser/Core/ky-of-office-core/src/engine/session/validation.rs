//! Session-level identity and operation-log validation.

use super::OfficeDocumentSession;
use crate::{Validatable, ValidationIssue, ValidationReport};

impl<State, Edit> Validatable for OfficeDocumentSession<State, Edit> {
    fn validate_report(&self) -> ValidationReport {
        let mut report = ValidationReport::new();

        if self.engine.as_str().trim().is_empty() {
            report.push(
                ValidationIssue::error("session.engine.empty", "Session engine id is required")
                    .with_path("engine"),
            );
        }

        if self.document_id.as_str().trim().is_empty() {
            report.push(
                ValidationIssue::error("session.document.empty", "Session document id is required")
                    .with_path("document_id"),
            );
        }

        report.extend_with_prefix(self.operation_log.validate_report(), "operation_log");
        for (index, operation) in self.operation_log.operations.iter().enumerate() {
            let path = format!("operation_log.operations[{index}]");
            if operation.engine != self.engine {
                report.push(
                    ValidationIssue::error(
                        "session.log.engine_mismatch",
                        format!(
                            "Logged operation engine '{}' does not match session engine '{}'",
                            operation.engine, self.engine
                        ),
                    )
                    .with_path(&path),
                );
            }

            if operation.document_id != self.document_id {
                report.push(
                    ValidationIssue::error(
                        "session.log.document_mismatch",
                        format!(
                            "Logged operation document '{}' does not match session document '{}'",
                            operation.document_id, self.document_id
                        ),
                    )
                    .with_path(&path),
                );
            }

            if operation.sequence > self.sequence {
                report.push(
                    ValidationIssue::error(
                        "session.log.sequence_after_session",
                        format!(
                            "Logged operation sequence {} is newer than session sequence {}",
                            operation.sequence, self.sequence
                        ),
                    )
                    .with_path(&path),
                );
            }
        }

        report
    }
}
