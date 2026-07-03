use super::{codec::XlsxClipboardTextCodec, options::XlsxClipboardTextOptions};
use crate::{
    CellPosition, XlsxCopyRangeRequest, XlsxPasteClipboardRequest, XlsxSheetRange,
    XlsxWorkbookError,
};
use serde::{Deserialize, Serialize};
use waraq_core::{ActorId, OperationId, TransactionId};

/// Request for copying a workbook sheet range as spreadsheet-compatible text.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct XlsxCopyRangeTextRequest {
    copy_range: XlsxCopyRangeRequest,
    options: XlsxClipboardTextOptions,
}

impl XlsxCopyRangeTextRequest {
    /// Create a text copy request targeting the active sheet.
    pub fn new(range: XlsxSheetRange) -> Self {
        Self {
            copy_range: XlsxCopyRangeRequest::new(range),
            options: XlsxClipboardTextOptions::default(),
        }
    }

    /// Target a specific workbook sheet by name.
    pub fn for_sheet(mut self, sheet_name: impl Into<String>) -> Self {
        self.copy_range = self.copy_range.for_sheet(sheet_name);
        self
    }

    /// Use explicit text serialization options.
    pub fn with_options(mut self, options: XlsxClipboardTextOptions) -> Self {
        self.options = options;
        self
    }

    /// Return the underlying range copy request.
    pub fn copy_range(&self) -> &XlsxCopyRangeRequest {
        &self.copy_range
    }

    /// Return the text serialization options.
    pub fn options(&self) -> XlsxClipboardTextOptions {
        self.options
    }

    pub(crate) fn target_sheet_name<'a>(&'a self, active_sheet_name: &'a str) -> &'a str {
        self.copy_range.target_sheet_name(active_sheet_name)
    }
}

/// Request for pasting spreadsheet-compatible text into a workbook sheet.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct XlsxPasteClipboardTextRequest {
    sheet_name: Option<String>,
    source_sheet_name: String,
    transaction_id: TransactionId,
    operation_id_prefix: OperationId,
    inverse_operation_id_prefix: OperationId,
    actor_id: ActorId,
    timestamp_ms: u64,
    target_start: CellPosition,
    text: String,
}

impl XlsxPasteClipboardTextRequest {
    /// Create a text paste request targeting the active sheet.
    pub fn new(
        transaction_id: impl Into<TransactionId>,
        operation_id_prefix: impl Into<OperationId>,
        inverse_operation_id_prefix: impl Into<OperationId>,
        actor_id: impl Into<ActorId>,
        timestamp_ms: u64,
        target_start: CellPosition,
        text: impl Into<String>,
    ) -> Self {
        Self {
            sheet_name: None,
            source_sheet_name: "clipboard".to_owned(),
            transaction_id: transaction_id.into(),
            operation_id_prefix: operation_id_prefix.into(),
            inverse_operation_id_prefix: inverse_operation_id_prefix.into(),
            actor_id: actor_id.into(),
            timestamp_ms,
            target_start,
            text: text.into(),
        }
    }

    /// Target a specific workbook sheet by name.
    pub fn for_sheet(mut self, sheet_name: impl Into<String>) -> Self {
        self.sheet_name = Some(sheet_name.into());
        self
    }

    /// Attach a display name for the external text source.
    pub fn with_source_sheet_name(mut self, source_sheet_name: impl Into<String>) -> Self {
        self.source_sheet_name = source_sheet_name.into();
        self
    }

    /// Return the requested sheet name, if this is not an active-sheet paste.
    pub fn sheet_name(&self) -> Option<&str> {
        self.sheet_name.as_deref()
    }

    /// Return the display name used by the decoded clipboard payload.
    pub fn source_sheet_name(&self) -> &str {
        &self.source_sheet_name
    }

    /// Return the transaction id used by the generated paste.
    pub fn transaction_id(&self) -> &TransactionId {
        &self.transaction_id
    }

    /// Return the operation id prefix used by generated forward operations.
    pub fn operation_id_prefix(&self) -> &OperationId {
        &self.operation_id_prefix
    }

    /// Return the operation id prefix used by generated inverse operations.
    pub fn inverse_operation_id_prefix(&self) -> &OperationId {
        &self.inverse_operation_id_prefix
    }

    /// Return the actor id used by generated operations.
    pub fn actor_id(&self) -> &ActorId {
        &self.actor_id
    }

    /// Return the timestamp used by generated operations.
    pub fn timestamp_ms(&self) -> u64 {
        self.timestamp_ms
    }

    /// Return the top-left target cell for the paste.
    pub fn target_start(&self) -> CellPosition {
        self.target_start
    }

    /// Return the raw spreadsheet-compatible text to paste.
    pub fn text(&self) -> &str {
        &self.text
    }

    pub(crate) fn target_sheet_name<'a>(&'a self, active_sheet_name: &'a str) -> &'a str {
        self.sheet_name
            .as_deref()
            .map(str::trim)
            .unwrap_or(active_sheet_name)
    }

    pub(crate) fn to_paste_request(
        &self,
        source_sheet_name: impl Into<String>,
    ) -> Result<XlsxPasteClipboardRequest, XlsxWorkbookError> {
        let payload = XlsxClipboardTextCodec::decode(source_sheet_name, &self.text)?;

        Ok(XlsxPasteClipboardRequest::new(
            self.transaction_id.clone(),
            self.operation_id_prefix.clone(),
            self.inverse_operation_id_prefix.clone(),
            self.actor_id.clone(),
            self.timestamp_ms,
            self.target_start,
            payload,
        )
        .with_formula_translation(false))
    }
}
