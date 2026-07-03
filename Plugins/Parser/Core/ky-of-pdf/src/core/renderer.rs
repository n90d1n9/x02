#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PdfRenderRequest {
    pub title: String,
}

impl PdfRenderRequest {
    pub fn new(title: impl Into<String>) -> Self {
        Self {
            title: title.into(),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PdfRenderSummary {
    pub title: String,
}

pub fn summarize_render_request(request: &PdfRenderRequest) -> PdfRenderSummary {
    PdfRenderSummary {
        title: request.title.clone(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn summarizes_render_request_title() {
        let request = PdfRenderRequest::new("Annual Report");

        assert_eq!(summarize_render_request(&request).title, "Annual Report");
    }
}
