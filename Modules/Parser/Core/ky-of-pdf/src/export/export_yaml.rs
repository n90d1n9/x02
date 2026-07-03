// ─────────────────────────────────────────────────────────────────────────────
// YAML Exporter
// ─────────────────────────────────────────────────────────────────────────────

fn to_yaml(result: &ExtractionResult) -> Result<String> {
    Ok(serde_yaml::to_string(result)?)
}

