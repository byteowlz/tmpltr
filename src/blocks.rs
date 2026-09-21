//! Fenced-block renderers: turn a fenced code block (e.g. ` ```mermaid `) into an
//! image via a configured external command.
//!
//! This module owns *no* domain knowledge. It is a registry of configured
//! renderers plus a content-hashed cache. Adding support for a new diagram tool
//! (d2, graphviz, plantuml, gnuplot, …) is a config entry, never a code change.
//!
//! Contract: a fence whose language matches a configured renderer becomes an
//! image; a fence whose language has no renderer stays a code listing. A
//! renderer that *is* configured but whose binary is missing or fails must fail
//! loud — silently rendering source as a code block would hide a broken setup.

use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;

use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};

use crate::error::{Error, Result};

/// One configured fenced-block renderer.
///
/// The command is a tokenized template (not a shell string). Only `{input}`
/// and `{output}` placeholders are substituted, and tokens are passed to the
/// process directly — there is no shell layer.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BlockRenderer {
    /// Tokenized command, e.g. `"d2 {input} {output}"`.
    pub command: String,
    /// Output extension, e.g. `"svg"` or `"png"`.
    pub output: String,
    /// Optional input extension override (defaults to the language name).
    #[serde(default)]
    pub input_ext: Option<String>,
}

/// Collection of configured renderers, keyed by fence language.
pub type BlockRenderers = HashMap<String, BlockRenderer>;

/// Languages commonly used for fenced *diagrams* (as opposed to code).
///
/// This is a tiny, slow-moving hint set, not a catalogue of code languages —
/// that question is the highlighter's job, not tmpltr's. It only decides
/// whether to nudge the user with a warning when such a fence has no
/// configured renderer. It never affects correctness: an unconfigured diagram
/// language still renders as a code listing.
///
/// Keep this small. New entries only when a diagram tool becomes common.
pub const DIAGRAM_LANGUAGES: &[&str] = &[
    "mermaid",
    "mmd",
    "d2",
    "dot",
    "graphviz",
    "plantuml",
    "uml",
    "gnuplot",
    "structurizr",
    "erd",
    "vega",
    "vega-lite",
    "blockdiag",
    "seqdiag",
    "actdiag",
    "wavedrom",
    "ditaa",
];

/// True when a fence language names a known diagram tool. Warning-only —
/// never used to decide how a block renders, only whether to nudge.
pub fn is_diagram_language(language: &str) -> bool {
    DIAGRAM_LANGUAGES.contains(&language)
}

/// Failure injected by tests to simulate a missing binary without touching PATH.
#[cfg(test)]
const MISSING_BINARY_SENTINEL: &str = "tmpltr-missing-renderer-binary-for-tests";

/// Resolve and render a fenced block to a cached image file.
///
/// Returns `Ok(Some(path))` when a renderer is configured (the path always
/// exists on success), `Ok(None)` when no renderer is configured for the
/// language (caller should treat it as a plain code listing), and `Err` only
/// when a configured renderer could not run to completion.
pub fn render(
    language: &str,
    source: &str,
    renderers: &BlockRenderers,
    cache_dir: &Path,
) -> Result<Option<PathBuf>> {
    let Some(renderer) = renderers.get(language) else {
        return Ok(None);
    };

    // The cached output is the build dependency, not the renderer. Two builds
    // with identical language + command + source reuse the same bytes, which
    // keeps `same inputs → same PDF` intact even for nondeterministic CLIs.
    let key = cache_key(language, &renderer.command, source);
    let out_ext = renderer.output.trim_start_matches('.');
    let cached = cache_dir.join(format!("block-{key}.{out_ext}"));

    if cached.exists() {
        return Ok(Some(cached));
    }

    fs::create_dir_all(cache_dir)?;
    let in_ext = renderer
        .input_ext
        .as_deref()
        .map(|e| e.trim_start_matches('.'))
        .unwrap_or(language);
    let input = cache_dir.join(format!("block-{key}.in.{in_ext}"));
    fs::write(&input, source)?;

    // Tokenize once (no shell layer). Parts are owned so the binary name and
    // the original command string can both be reported in errors without a
    // dangling borrow into the token iterator.
    let expanded = render_command(&renderer.command, &input, &cached);
    let parts: Vec<String> = expanded.split_whitespace().map(String::from).collect();
    let binary = parts
        .first()
        .cloned()
        .ok_or_else(|| Error::RendererFailed {
            language: language.to_string(),
            command: renderer.command.clone(),
            exit: "empty command".to_string(),
            stderr: String::new(),
        })?;

    #[cfg(not(test))]
    let binary_missing = which::which(&binary).is_err();
    #[cfg(test)]
    let binary_missing = binary == MISSING_BINARY_SENTINEL || which::which(&binary).is_err();

    if binary_missing {
        let _ = fs::remove_file(&input);
        return Err(Error::RendererBinaryNotFound {
            language: language.to_string(),
            binary: binary.clone(),
            command: expanded,
            install_hints: install_hints(language, &binary),
        });
    }

    let output = Command::new(&binary).args(&parts[1..]).output();

    match output {
        Ok(out) if out.status.success() => {
            if !cached.exists() {
                let _ = fs::remove_file(&input);
                return Err(Error::RendererNoOutput {
                    language: language.to_string(),
                    command: expanded,
                    output: cached,
                });
            }
            let _ = fs::remove_file(&input);
            Ok(Some(cached))
        }
        Ok(out) => {
            let _ = fs::remove_file(&input);
            Err(Error::RendererFailed {
                language: language.to_string(),
                command: expanded,
                exit: exit_string(&out),
                stderr: String::from_utf8_lossy(&out.stderr).into_owned(),
            })
        }
        // A failed spawn is almost always the OS reporting "binary not found".
        Err(e) if matches!(e.kind(), std::io::ErrorKind::NotFound) => {
            let _ = fs::remove_file(&input);
            let hints = install_hints(language, &binary);
            Err(Error::RendererBinaryNotFound {
                language: language.to_string(),
                binary,
                command: expanded,
                install_hints: hints,
            })
        }
        Err(e) => {
            let _ = fs::remove_file(&input);
            Err(Error::RendererFailed {
                language: language.to_string(),
                command: expanded,
                exit: e.kind().to_string(),
                stderr: e.to_string(),
            })
        }
    }
}

/// Substitute `{input}`/`{output}` placeholders. The original template is
/// returned verbatim (tokens preserved) for error messages and binary lookup.
fn render_command(template: &str, input: &Path, output: &Path) -> String {
    template
        .replace("{input}", &input.to_string_lossy())
        .replace("{output}", &output.to_string_lossy())
}

/// Deterministic cache key: same language + command + source → same bytes.
fn cache_key(language: &str, command: &str, source: &str) -> String {
    let mut hasher = Sha256::new();
    hasher.update(language.as_bytes());
    hasher.update([0u8]);
    hasher.update(command.as_bytes());
    hasher.update([0u8]);
    hasher.update(source.as_bytes());
    let digest = hasher.finalize();
    // 16 hex chars is ample collision resistance for a local block cache.
    let mut out = String::with_capacity(16);
    for byte in digest.iter().take(8) {
        out.push_str(&format!("{byte:02x}"));
    }
    out
}

fn exit_string(out: &std::process::Output) -> String {
    out.status
        .code()
        .map(|c| c.to_string())
        .unwrap_or_else(|| "signal".to_string())
}

/// Concise, per-language install hints. Not an exhaustive package list — just
/// enough that the error points at the right tool instead of leaving the user
/// to search. Unknown tools get a generic hint.
fn install_hints(language: &str, binary: &str) -> String {
    match language {
        "d2" => "https://d2lang.com (release binary or `brew install d2`)".to_string(),
        "mermaid" | "mmd" => {
            "npm i -g @mermaid-js/mermaid-cli (needs Node + headless Chromium)".to_string()
        }
        "dot" | "graphviz" => {
            "graphviz (`brew install graphviz` / `apt install graphviz`)".to_string()
        }
        "plantuml" => "plantuml (requires Java)".to_string(),
        "gnuplot" => "gnuplot (`brew install gnuplot` / `apt install gnuplot`)".to_string(),
        _ => format!("install `{binary}` and ensure it is on PATH"),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::tempdir;

    #[test]
    fn unconfigured_language_is_none() {
        let dir = tempdir().unwrap();
        let renderers: BlockRenderers = HashMap::new();
        let out = render("d2", "x -> y", &renderers, dir.path()).unwrap();
        assert!(out.is_none());
    }

    #[test]
    fn configured_renderer_caches_result() {
        let dir = tempdir().unwrap();
        let mut renderers: BlockRenderers = HashMap::new();
        // A renderer that just copies the input to the output. The sentinel
        // ext lets us run it without any external binary on PATH.
        // A renderer that just copies the input to the output. No shell is
        // involved — tokens are passed straight to the process — so the
        // command is `cp {input} {output}`.
        renderers.insert(
            "test-copy".to_string(),
            BlockRenderer {
                command: "cp {input} {output}".to_string(),
                output: "svg".to_string(),
                input_ext: Some("txt".to_string()),
            },
        );
        let first = render("test-copy", "hello", &renderers, dir.path()).expect("first render");
        assert!(first.as_ref().map(|p| p.exists()).unwrap_or(false));
        let first_path = first.unwrap();

        // Second call with identical source returns the cached file path.
        let second = render("test-copy", "hello", &renderers, dir.path()).expect("second render");
        assert_eq!(second.unwrap(), first_path);
    }

    #[test]
    fn different_source_produces_different_cache_key() {
        let a = cache_key("d2", "d2 {input} {output}", "a -> b");
        let b = cache_key("d2", "d2 {input} {output}", "a -> c");
        assert_ne!(a, b);
    }

    #[test]
    fn different_command_produces_different_cache_key() {
        let a = cache_key("d2", "d2 {input} {output}", "a -> b");
        let b = cache_key("d2", "d2 --layout=elk {input} {output}", "a -> b");
        assert_ne!(a, b);
    }

    #[test]
    fn missing_binary_fails_loud() {
        let dir = tempdir().unwrap();
        let mut renderers: BlockRenderers = HashMap::new();
        renderers.insert(
            "d2".to_string(),
            BlockRenderer {
                command: format!("{MISSING_BINARY_SENTINEL} {{input}} {{output}}"),
                output: "svg".to_string(),
                input_ext: None,
            },
        );
        let err =
            render("d2", "a -> b", &renderers, dir.path()).expect_err("missing binary should fail");
        assert!(matches!(
            err,
            Error::RendererBinaryNotFound { ref language, .. } if language == "d2"
        ));
    }

    #[test]
    fn render_command_substitutes_placeholders() {
        let out = render_command(
            "d2 {input} {output}",
            Path::new("/tmp/a.d2"),
            Path::new("/tmp/a.svg"),
        );
        assert_eq!(out, "d2 /tmp/a.d2 /tmp/a.svg");
    }
}
