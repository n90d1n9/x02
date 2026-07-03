use thiserror::Error;

/// All errors that can be produced by this crate.
#[derive(Debug, Error)]
pub enum DocxError {
   
}

/// Convenience alias used throughout the crate.
pub type Result<T> = std::result::Result<T, DocxError>;
