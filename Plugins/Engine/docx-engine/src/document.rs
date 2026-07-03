#[derive(Debug, Clone, PartialEq, Eq)]
pub struct DocxDocumentRequest {
    pub title: String,
}

impl DocxDocumentRequest {
    pub fn new(title: impl Into<String>) -> Self {
        Self {
            title: title.into(),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct DocxDocumentSummary {
    pub title: String,
}

pub fn summarize_document_request(request: &DocxDocumentRequest) -> DocxDocumentSummary {
    DocxDocumentSummary {
        title: request.title.clone(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn summarizes_document_request() {
        let request = DocxDocumentRequest::new("Proposal");

        assert_eq!(summarize_document_request(&request).title, "Proposal");
    }
}
