mod batch;
mod cursor;
mod error;

pub use batch::{collect_operations_after, validate_incoming_batch, OfficeOperationBatch};
pub use cursor::OfficeSyncCursor;
pub use error::OfficeSyncError;

#[cfg(test)]
mod tests;
