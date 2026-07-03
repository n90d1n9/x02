


// ═══════════════════════════════════════════════
// Form fields
// ═══════════════════════════════════════════════

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum FieldType {
    Text,
    Checkbox,
    RadioButton,
    ListBox,
    ComboBox,
    PushButton,
    Signature,
    Unknown,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FormField {
    pub name: String,
    pub field_type: FieldType,
    pub value: Option<String>,
    pub default_value: Option<String>,
    pub read_only: bool,
    pub required: bool,
    pub options: Vec<String>,
    /// Widget rectangle [x1, y1, x2, y2] on the page.
    pub rect: Option<[f64; 4]>,
    /// Page index of the widget annotation.
    pub page_index: Option<usize>,
}
