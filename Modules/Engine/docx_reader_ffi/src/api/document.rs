//! The entire Dart-facing surface of this crate.
//!
//! Design choice, deliberately: the boundary is **opaque `u32` document
//! handles + JSON strings**, not a 1:1 mirror of every Rust type in
//! `rich_doc_core`. That's the future-proofing move. If it mirrored
//! `Op`/`NodeKind`/etc. directly, every new block type or op variant
//! would require regenerating bindings and touching the Dart side. With
//! a JSON boundary, `rich_doc_core` can grow its schema freely — the
//! FFI surface (6 functions) never changes, and `describe_schema()`
//! lets the Dart/agent side discover new capabilities at runtime
//! instead of at codegen time.
//!
//! This also means the exact same JSON commands work identically
//! whether they come from a Flutter gesture handler or an LLM agent's
//! tool call — see `rich_doc_core::agent`.

use rich_doc_core::{agent, serialize, Tree};
use std::collections::HashMap;
use std::sync::{Mutex, OnceLock};

static REGISTRY: OnceLock<Mutex<HashMap<u32, Mutex<Tree>>>> = OnceLock::new();
static NEXT_HANDLE: OnceLock<Mutex<u32>> = OnceLock::new();

fn registry() -> &'static Mutex<HashMap<u32, Mutex<Tree>>> {
    REGISTRY.get_or_init(|| Mutex::new(HashMap::new()))
}

fn alloc_handle() -> u32 {
    let lock = NEXT_HANDLE.get_or_init(|| Mutex::new(0));
    let mut next = lock.lock().unwrap();
    let handle = *next;
    *next += 1;
    handle
}

/// Create a new, empty document and return an opaque handle to it.
/// Every other function here takes that handle.
#[flutter_rust_bridge::frb(sync)]
pub fn create_document() -> u32 {
    let handle = alloc_handle();
    registry().lock().unwrap().insert(handle, Mutex::new(Tree::new_empty()));
    handle
}

/// Load a document from its full-fidelity JSON representation (as
/// produced by `get_snapshot`) and return a handle to it.
#[flutter_rust_bridge::frb(sync)]
pub fn load_document(json: String) -> Result<u32, String> {
    let tree = serialize::from_json(&json).map_err(|e| e.to_string())?;
    let handle = alloc_handle();
    registry().lock().unwrap().insert(handle, Mutex::new(tree));
    Ok(handle)
}

/// Release a document's memory. Idempotent — closing an already-closed
/// or unknown handle is a no-op, not an error, so Dart-side `dispose()`
/// never has to guard against double-close.
#[flutter_rust_bridge::frb(sync)]
pub fn close_document(handle: u32) {
    registry().lock().unwrap().remove(&handle);
}

/// Full-fidelity JSON snapshot (includes internal node ids). Use this
/// for local persistence / save-load, or to send to a backend that
/// wants to store exact editor state (e.g. to resume editing later with
/// stable node ids for comments/anchors).
#[flutter_rust_bridge::frb(sync)]
pub fn get_snapshot(handle: u32) -> Result<String, String> {
    with_tree(handle, |tree| serialize::to_json(tree).map_err(|e| e.to_string()))
}

/// Plain nested JSON with no internal ids — the shape to hand to a
/// backend that just wants content, or to splice into an LLM's context
/// window.
#[flutter_rust_bridge::frb(sync)]
pub fn get_portable_snapshot(handle: u32) -> Result<String, String> {
    with_tree(handle, |tree| agent::portable_snapshot(tree).map(|v| v.to_string()).map_err(|e| e.to_string()))
}

/// The single edit entry point. `command_json` is
/// `{"ops": [...Command...], "reason": "optional string"}` (see
/// `describe_schema`). Called by the Flutter UI (translating
/// keystrokes/gestures into commands) and by an agent tool call —
/// same vocabulary, same validation, same undo support, no drift
/// possible between "what a human can do" and "what an agent can do".
///
/// Always returns a JSON `AgentResult`; never throws across the bridge,
/// so Dart has one uniform way to check `result.ok` instead of catching
/// exceptions that crossed FFI.
#[flutter_rust_bridge::frb(sync)]
pub fn apply_command(handle: u32, command_json: String) -> String {
    let reg = registry().lock().unwrap();
    let Some(tree_mutex) = reg.get(&handle) else {
        return error_result(format!("unknown document handle {handle}"));
    };
    let mut tree = tree_mutex.lock().unwrap();
    let result = agent::execute_command_json(&mut tree, &command_json);
    serde_json::to_string(&result).unwrap_or_else(|e| error_result(format!("failed to serialize result: {e}")))
}

/// Static schema description — identical for every document, no handle
/// needed. Fetch once at app/session startup and (re-)send it as an LLM
/// tool definition, or use it to drive Dart-side editor UI capability
/// checks (e.g. "does this schema support tables?").
#[flutter_rust_bridge::frb(sync)]
pub fn describe_schema() -> String {
    agent::describe_schema().to_string()
}

fn with_tree<T>(handle: u32, f: impl FnOnce(&Tree) -> Result<T, String>) -> Result<T, String> {
    let reg = registry().lock().unwrap();
    let tree_mutex = reg.get(&handle).ok_or_else(|| format!("unknown document handle {handle}"))?;
    let tree = tree_mutex.lock().unwrap();
    f(&tree)
}

fn error_result(message: String) -> String {
    serde_json::json!({ "ok": false, "outcome": null, "error": message }).to_string()
}
