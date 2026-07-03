use crate::{OfficeSyncError, TransactionError, ValidationReport};

#[derive(Debug, Clone, PartialEq)]
pub enum OfficeSessionError<E> {
    Validation(ValidationReport),
    Apply(E),
    Transaction(TransactionError),
    Sync(OfficeSyncError),
}

impl<E> OfficeSessionError<E> {
    pub fn validation(report: ValidationReport) -> Self {
        Self::Validation(report)
    }

    pub fn apply(error: E) -> Self {
        Self::Apply(error)
    }

    pub fn transaction(error: TransactionError) -> Self {
        Self::Transaction(error)
    }

    pub fn sync(error: OfficeSyncError) -> Self {
        Self::Sync(error)
    }
}
