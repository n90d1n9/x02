use super::{ValidationIssue, ValidationSeverity};
use serde::de::DeserializeOwned;
use serde::{Deserialize, Serialize};

pub type ValidationResult<T> = Result<T, ValidationReport>;

#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct ValidationReport {
    pub issues: Vec<ValidationIssue>,
}

impl ValidationReport {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn from_issue(issue: ValidationIssue) -> Self {
        Self {
            issues: vec![issue],
        }
    }

    pub fn push(&mut self, issue: ValidationIssue) {
        self.issues.push(issue);
    }

    pub fn error(&mut self, code: impl Into<String>, message: impl Into<String>) {
        self.push(ValidationIssue::error(code, message));
    }

    pub fn warning(&mut self, code: impl Into<String>, message: impl Into<String>) {
        self.push(ValidationIssue::warning(code, message));
    }

    pub fn info(&mut self, code: impl Into<String>, message: impl Into<String>) {
        self.push(ValidationIssue::info(code, message));
    }

    pub fn extend(&mut self, other: ValidationReport) {
        self.issues.extend(other.issues);
    }

    pub fn extend_with_prefix(&mut self, other: ValidationReport, prefix: impl AsRef<str>) {
        self.issues.extend(
            other
                .issues
                .into_iter()
                .map(|issue| issue.with_path_prefix(prefix.as_ref())),
        );
    }

    pub fn issues(&self) -> &[ValidationIssue] {
        &self.issues
    }

    pub fn len(&self) -> usize {
        self.issues.len()
    }

    pub fn is_empty(&self) -> bool {
        self.issues.is_empty()
    }

    pub fn error_count(&self) -> usize {
        self.count_by_severity(ValidationSeverity::Error)
    }

    pub fn warning_count(&self) -> usize {
        self.count_by_severity(ValidationSeverity::Warning)
    }

    pub fn info_count(&self) -> usize {
        self.count_by_severity(ValidationSeverity::Info)
    }

    pub fn is_valid(&self) -> bool {
        self.error_count() == 0
    }

    pub fn require_valid(self) -> ValidationResult<()> {
        if self.is_valid() {
            Ok(())
        } else {
            Err(self)
        }
    }

    pub fn to_json(&self) -> serde_json::Result<String> {
        serde_json::to_string(self)
    }

    pub fn from_json(json: &str) -> serde_json::Result<Self>
    where
        Self: DeserializeOwned,
    {
        serde_json::from_str(json)
    }

    fn count_by_severity(&self, severity: ValidationSeverity) -> usize {
        self.issues
            .iter()
            .filter(|issue| issue.severity == severity)
            .count()
    }
}
