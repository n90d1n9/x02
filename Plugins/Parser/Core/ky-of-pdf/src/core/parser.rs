#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PdfParseRequest {
    pub bytes: Vec<u8>,
}

impl PdfParseRequest {
    pub fn from_bytes(bytes: impl Into<Vec<u8>>) -> Self {
        Self {
            bytes: bytes.into(),
        }
    }

    pub fn is_empty(&self) -> bool {
        self.bytes.is_empty()
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PdfParseSummary {
    pub byte_len: usize,
}

pub fn summarize_request(request: &PdfParseRequest) -> PdfParseSummary {
    PdfParseSummary {
        byte_len: request.bytes.len(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn summarizes_parse_request_size() {
        let request = PdfParseRequest::from_bytes(b"%PDF".to_vec());

        assert!(!request.is_empty());
        assert_eq!(summarize_request(&request).byte_len, 4);
    }
}
