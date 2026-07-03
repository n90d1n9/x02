use super::{ValidationReport, ValidationResult};

pub trait Validatable {
    fn validate_report(&self) -> ValidationReport;

    fn is_valid(&self) -> bool {
        self.validate_report().is_valid()
    }

    fn require_valid(&self) -> ValidationResult<()> {
        self.validate_report().require_valid()
    }
}
