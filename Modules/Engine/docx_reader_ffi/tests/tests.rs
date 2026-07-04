use crate::api::document::*;

#[test]
fn full_lifecycle_through_the_ffi_surface() {
    let handle = create_document();

    // Discover the first paragraph's text node id via a snapshot round
    // trip, exactly as Dart would (it has no compile-time knowledge of
    // NodeId — it's just a number inside JSON here).
    let snapshot = get_snapshot(handle).unwrap();
    let v: serde_json::Value = serde_json::from_str(&snapshot).unwrap();
    let root_id = v["root"].as_u64().unwrap();
    let doc_node = &v["nodes"][root_id.to_string()]["kind"];
    let para_id = doc_node["children"][0].as_u64().unwrap();
    let para_node = &v["nodes"][para_id.to_string()]["kind"];
    let text_id = para_node["children"][0].as_u64().unwrap();

    // A human edit: type some text (raw op via the command wrapper).
    let cmd = format!(
        r#"{{"ops": [{{"command": "op", "payload": {{"op": "insert_text", "node": {text_id}, "offset": 0, "text": "Hello from Flutter"}}}}]}}"#
    );
    let result_json = apply_command(handle, cmd);
    let result: serde_json::Value = serde_json::from_str(&result_json).unwrap();
    assert_eq!(result["ok"], true, "apply_command failed: {result_json}");

    // An agent edit on the same document, same entry point.
    let agent_cmd = format!(
        r#"{{"ops": [{{"command": "add_mark_range", "node": {text_id}, "start": 0, "end": 5, "mark": {{"type": "bold"}}}}], "reason": "agent bolding greeting"}}"#
    );
    let agent_result_json = apply_command(handle, agent_cmd);
    let agent_result: serde_json::Value = serde_json::from_str(&agent_result_json).unwrap();
    assert_eq!(agent_result["ok"], true, "agent command failed: {agent_result_json}");

    // Portable snapshot should reflect both edits without leaking ids.
    let portable = get_portable_snapshot(handle).unwrap();
    assert!(portable.contains("Hello"));
    assert!(!portable.contains("\"nodes\""), "portable snapshot should not look like the internal wire format");

    // Unknown handle -> graceful JSON error, not a panic.
    let bad = apply_command(9999, "{}".into());
    let bad_v: serde_json::Value = serde_json::from_str(&bad).unwrap();
    assert_eq!(bad_v["ok"], false);

    close_document(handle);
    // Closing again is a no-op, not an error.
    close_document(handle);
}

#[test]
fn schema_is_discoverable_without_a_handle() {
    let schema = describe_schema();
    let v: serde_json::Value = serde_json::from_str(&schema).unwrap();
    assert!(v.get("primitive_ops").is_some());
    assert!(v.get("composite_commands").is_some());
}

#[test]
fn load_document_round_trips_a_snapshot() {
    let handle = create_document();
    let snap = get_snapshot(handle).unwrap();
    let handle2 = load_document(snap.clone()).unwrap();
    let snap2 = get_snapshot(handle2).unwrap();
    let v1: serde_json::Value = serde_json::from_str(&snap).unwrap();
    let v2: serde_json::Value = serde_json::from_str(&snap2).unwrap();
    assert_eq!(v1, v2, "should be structurally identical regardless of HashMap key order");
}
