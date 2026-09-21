//! Markdown to Typst conversion
//!
//! Converts Markdown content to Typst markup for embedding in templates.
//!
//! Fenced code blocks whose language matches a configured block renderer
//! (`[blocks.*]` in config) are rendered to an image and emitted as `#image`.
//! Fenced blocks without a renderer stay Typst code listings (language passed
//! through so Typst's syntax highlighting applies). A configured renderer that
//! fails is surfaced loudly — it is never silently demoted to a code listing.

use std::collections::HashMap;
use std::path::Path;

use pulldown_cmark::{CodeBlockKind, Event, Options, Parser, Tag, TagEnd};

use crate::blocks::{render, BlockRenderers};
use crate::error::Result;

/// Sentinel wrapping a footnote placeholder so we can resolve it after the full
/// document has streamed (definitions usually follow their references). Uses a
/// Unicode noncharacter prefix so it cannot collide with authored text.
const FN_SENTINEL: char = '\u{FDD0}';

/// Convert Markdown text to Typst markup with no block renderers configured.
///
/// Preserved for tests and simple callers; fenced blocks always become code
/// listings here.
pub fn markdown_to_typst(markdown: &str) -> Result<String> {
    markdown_to_typst_with(
        markdown,
        &BlockRenderers::default(),
        std::path::Path::new(""),
    )
}

/// Convert Markdown text to Typst markup, dispatching configured fenced-block
/// languages to external renderers. The cache directory holds content-hashed
/// rendered images.
pub fn markdown_to_typst_with(
    markdown: &str,
    renderers: &BlockRenderers,
    cache_dir: &Path,
) -> Result<String> {
    let mut options = Options::empty();
    options.insert(Options::ENABLE_STRIKETHROUGH);
    options.insert(Options::ENABLE_TABLES);
    options.insert(Options::ENABLE_FOOTNOTES);
    options.insert(Options::ENABLE_TASKLISTS);

    let parser = Parser::new_ext(markdown, options);
    let mut converter = TypstConverter::new(renderers, cache_dir);

    for event in parser {
        converter.process_event(event)?;
    }

    Ok(converter.finish())
}

/// Converter state machine
struct TypstConverter<'a> {
    /// Active output buffer. Swapped out while collecting a footnote
    /// definition so the same emit methods write into the footnote body.
    output: String,
    /// Saved main output while inside a footnote definition.
    footnote_stack: Vec<String>,
    /// Collected footnote bodies keyed by label.
    footnote_bodies: HashMap<String, String>,
    /// Label of the footnote definition currently being collected, if any.
    current_footnote: Option<String>,
    /// Whether we are currently inside a fenced code block.
    in_code_block: bool,
    /// Language of the current fenced block (empty for indented blocks).
    code_language: String,
    /// Buffered source of the current fenced block (rendered only on close).
    code_buffer: String,
    /// Whether the current fenced block has already been emitted as a code
    /// listing (set when no renderer applies, so Text events append inline).
    code_emitted_as_listing: bool,
    list_depth: usize,
    /// Per-depth flag: was this list started as ordered?
    ordered_stack: Vec<bool>,
    in_table: bool,
    table_alignments: Vec<pulldown_cmark::Alignment>,
    table_cell_index: usize,
    renderers: &'a BlockRenderers,
    cache_dir: &'a Path,
}

impl<'a> TypstConverter<'a> {
    fn new(renderers: &'a BlockRenderers, cache_dir: &'a Path) -> Self {
        Self {
            output: String::new(),
            footnote_stack: Vec::new(),
            footnote_bodies: HashMap::new(),
            current_footnote: None,
            in_code_block: false,
            code_language: String::new(),
            code_buffer: String::new(),
            code_emitted_as_listing: false,
            list_depth: 0,
            ordered_stack: Vec::new(),
            in_table: false,
            table_alignments: Vec::new(),
            table_cell_index: 0,
            renderers,
            cache_dir,
        }
    }

    fn process_event(&mut self, event: Event) -> Result<()> {
        match event {
            Event::Start(tag) => self.start_tag(tag),
            Event::End(tag) => self.end_tag(tag),
            Event::Text(text) => {
                self.text(&text);
                Ok(())
            }
            Event::Code(code) => {
                self.inline_code(&code);
                Ok(())
            }
            Event::SoftBreak => {
                self.soft_break();
                Ok(())
            }
            Event::HardBreak => {
                self.hard_break();
                Ok(())
            }
            Event::Rule => {
                self.rule();
                Ok(())
            }
            Event::FootnoteReference(label) => {
                // Defer resolution: the body is collected by finish() once the
                // whole document has streamed.
                self.output.push_str("#footnote[");
                self.output.push(FN_SENTINEL);
                self.output.push_str(&label);
                self.output.push(FN_SENTINEL);
                self.output.push(']');
                Ok(())
            }
            Event::TaskListMarker(marker) => {
                // Render the checkbox glyph at the start of the list item body.
                self.output.push_str(if marker { "☑ " } else { "☐ " });
                Ok(())
            }
            // Inline HTML, math, etc. are intentionally ignored.
            _ => Ok(()),
        }
    }

    fn start_tag(&mut self, tag: Tag) -> Result<()> {
        match tag {
            Tag::Paragraph => {}
            Tag::Heading { level, .. } => {
                let marker = "=".repeat(level as usize);
                self.output.push_str(&marker);
                self.output.push(' ');
            }
            Tag::BlockQuote(_) => {
                self.output.push_str("#quote[\n");
            }
            Tag::CodeBlock(kind) => {
                self.in_code_block = true;
                self.code_buffer.clear();
                self.code_emitted_as_listing = false;
                self.code_language = match kind {
                    CodeBlockKind::Fenced(lang) => {
                        lang.split_whitespace().next().unwrap_or("").to_string()
                    }
                    CodeBlockKind::Indented => String::new(),
                };
            }
            Tag::List(start) => {
                self.list_depth += 1;
                self.ordered_stack.push(start.is_some());
                if let Some(n) = start {
                    if n != 1 {
                        // Typst enumerations start at 1; a custom start can't be
                        // expressed directly. Left as a known limitation.
                    }
                }
            }
            Tag::Item => {
                let indent = "  ".repeat(self.list_depth.saturating_sub(1));
                self.output.push_str(&indent);
                let ordered = self.ordered_stack.last().copied().unwrap_or(false);
                self.output.push_str(if ordered { "+ " } else { "- " });
            }
            Tag::Emphasis => {
                self.output.push('_');
            }
            Tag::Strong => {
                self.output.push('*');
            }
            Tag::Strikethrough => {
                self.output.push_str("#strike[");
            }
            Tag::Link { dest_url, .. } => {
                self.output.push_str("#link(\"");
                self.output.push_str(&dest_url);
                self.output.push_str("\")[");
            }
            Tag::Image { dest_url, .. } => {
                self.output.push_str("#image(\"");
                self.output.push_str(&dest_url);
                self.output.push_str("\")");
            }
            Tag::Table(alignments) => {
                self.in_table = true;
                self.table_alignments = alignments;
                self.output.push_str("#table(\n  columns: (");
                for (i, _) in self.table_alignments.iter().enumerate() {
                    if i > 0 {
                        self.output.push_str(", ");
                    }
                    self.output.push_str("auto");
                }
                self.output.push_str("),\n");
            }
            Tag::TableHead => {
                self.table_cell_index = 0;
            }
            Tag::TableRow => {
                self.table_cell_index = 0;
            }
            Tag::TableCell => {
                self.output.push_str("  [");
            }
            Tag::FootnoteDefinition(label) => {
                // Begin collecting this definition's body into a fresh buffer.
                self.current_footnote = Some(label.to_string());
                let saved = std::mem::take(&mut self.output);
                self.footnote_stack.push(saved);
            }
            _ => {}
        }
        Ok(())
    }

    fn end_tag(&mut self, tag: TagEnd) -> Result<()> {
        match tag {
            TagEnd::Paragraph => {
                self.output.push_str("\n\n");
            }
            TagEnd::Heading(_) => {
                self.output.push('\n');
            }
            TagEnd::BlockQuote(_) => {
                self.output.push_str("]\n");
            }
            TagEnd::CodeBlock => {
                self.in_code_block = false;
                let language = std::mem::take(&mut self.code_language);
                let source = std::mem::take(&mut self.code_buffer);
                if !language.is_empty() {
                    match render(&language, &source, self.renderers, self.cache_dir)? {
                        Some(path) => {
                            // Absolute path with typst --root "/" resolves to the
                            // filesystem location of the rendered image.
                            self.output.push_str("#image(\"");
                            self.output.push_str(&path.to_string_lossy());
                            self.output.push_str("\")\n");
                        }
                        None => {
                            // No renderer configured — emit as a code listing
                            // with the language passed through for highlighting.
                            self.output.push_str("```");
                            self.output.push_str(&language);
                            self.output.push('\n');
                            self.output.push_str(&source);
                            self.output.push_str("\n```\n");
                        }
                    }
                } else {
                    self.output.push_str("```\n");
                    self.output.push_str(&source);
                    self.output.push_str("\n```\n");
                }
                self.code_emitted_as_listing = false;
            }
            TagEnd::List(_) => {
                self.list_depth = self.list_depth.saturating_sub(1);
                self.ordered_stack.pop();
                if self.list_depth == 0 {
                    self.output.push('\n');
                }
            }
            TagEnd::Item => {
                self.output.push('\n');
            }
            TagEnd::Emphasis => {
                self.output.push('_');
            }
            TagEnd::Strong => {
                self.output.push('*');
            }
            TagEnd::Strikethrough => {
                self.output.push(']');
            }
            TagEnd::Link => {
                self.output.push(']');
            }
            TagEnd::Image => {}
            TagEnd::Table => {
                self.in_table = false;
                self.output.push_str(")\n");
            }
            TagEnd::TableHead => {
                self.output.push('\n');
            }
            TagEnd::TableRow => {
                self.output.push('\n');
            }
            TagEnd::TableCell => {
                self.output.push_str("],");
                self.table_cell_index += 1;
            }
            TagEnd::FootnoteDefinition => {
                // Restore the main buffer and store the collected body.
                let body = std::mem::take(&mut self.output);
                if let Some(main) = self.footnote_stack.pop() {
                    self.output = main;
                }
                if let Some(label) = self.current_footnote.take() {
                    self.footnote_bodies.insert(label, body.trim().to_string());
                }
            }
            _ => {}
        }
        Ok(())
    }

    fn text(&mut self, text: &str) {
        if self.in_code_block {
            // Buffer fenced-block source verbatim; rendering happens on close.
            if !self.code_emitted_as_listing {
                self.code_buffer.push_str(text);
            }
        } else {
            let escaped = escape_typst(text);
            self.output.push_str(&escaped);
        }
    }

    fn inline_code(&mut self, code: &str) {
        self.output.push('`');
        self.output.push_str(code);
        self.output.push('`');
    }

    fn soft_break(&mut self) {
        self.output.push(' ');
    }

    fn hard_break(&mut self) {
        self.output.push_str(" \\\n");
    }

    fn rule(&mut self) {
        self.output.push_str("#line(length: 100%)\n");
    }

    fn finish(mut self) -> String {
        // Resolve deferred footnote references now that all definitions have
        // been collected. An unresolved reference (no matching definition) is
        // left as an empty footnote rather than dropping silently.
        if !self.footnote_bodies.is_empty() {
            self.resolve_footnotes();
        }
        while self.output.ends_with('\n') {
            self.output.pop();
        }
        self.output
    }

    fn resolve_footnotes(&mut self) {
        let mut out = String::with_capacity(self.output.len());
        let mut rest = self.output.as_str();
        while let Some(start) = rest.find(FN_SENTINEL) {
            out.push_str(&rest[..start]);
            let after = &rest[start + FN_SENTINEL.len_utf8()..];
            match after.find(FN_SENTINEL) {
                Some(end) => {
                    let label = &after[..end];
                    let body = self.footnote_bodies.get(label).cloned().unwrap_or_default();
                    out.push_str(&body);
                    rest = &after[end + FN_SENTINEL.len_utf8()..];
                }
                None => {
                    // Unterminated sentinel — shouldn't happen, but don't panic.
                    out.push_str(after);
                    break;
                }
            }
        }
        out.push_str(rest);
        self.output = out;
    }
}

/// Escape special Typst characters in plain text
pub fn escape_typst(text: &str) -> String {
    let mut result = String::with_capacity(text.len());

    for ch in text.chars() {
        match ch {
            '#' => result.push_str("\\#"),
            '$' => result.push_str("\\$"),
            '*' => result.push_str("\\*"),
            '_' => result.push_str("\\_"),
            '`' => result.push_str("\\`"),
            '<' => result.push_str("\\<"),
            '>' => result.push_str("\\>"),
            '@' => result.push_str("\\@"),
            '[' => result.push_str("\\["),
            ']' => result.push_str("\\]"),
            _ => result.push(ch),
        }
    }

    result
}

#[cfg(test)]
mod tests {
    use super::*;

    fn conv(md: &str) -> String {
        markdown_to_typst(md).unwrap()
    }

    #[test]
    fn test_simple_text() {
        assert_eq!(conv("Hello world"), "Hello world");
    }

    #[test]
    fn test_bold() {
        assert_eq!(conv("This is **bold** text"), "This is *bold* text");
    }

    #[test]
    fn test_italic() {
        assert_eq!(conv("This is *italic* text"), "This is _italic_ text");
    }

    #[test]
    fn test_heading() {
        let result = conv("# Heading 1\n\nContent");
        assert!(result.starts_with("= Heading 1"));
    }

    #[test]
    fn test_unordered_list() {
        let result = conv("- Item 1\n- Item 2");
        assert!(result.contains("- Item 1"));
        assert!(result.contains("- Item 2"));
        assert!(!result.contains("+ "));
    }

    #[test]
    fn test_ordered_list_uses_plus_marker() {
        let result = conv("1. First\n2. Second\n3. Third");
        assert!(
            result.contains("+ First"),
            "ordered list should use '+' marker, got: {result}"
        );
        assert!(result.contains("+ Second"));
        assert!(result.contains("+ Third"));
    }

    #[test]
    fn test_mixed_list_types() {
        let result = conv("- bullet\n  1. nested ordered\n  2. another");
        assert!(result.contains("- bullet"));
        assert!(result.contains("+ nested ordered"));
    }

    #[test]
    fn test_code_block_passes_language_through() {
        let result = conv("```rust\nfn main() {}\n```");
        assert!(
            result.contains("```rust"),
            "fence language should pass through, got: {result}"
        );
    }

    #[test]
    fn test_code_block_without_renderer_is_listing() {
        let renderers = BlockRenderers::default();
        let result =
            markdown_to_typst_with("```d2\nx -> y\n```", &renderers, Path::new("")).unwrap();
        assert!(result.contains("```d2"));
        assert!(result.contains("x -> y"));
    }

    #[test]
    fn test_escape() {
        assert_eq!(escape_typst("Price: $100 #tag"), "Price: \\$100 \\#tag");
    }

    #[test]
    fn test_footnote_resolves_to_body() {
        let result = conv("See this[^1].\n\n[^1]: the note body");
        assert!(
            result.contains("#footnote[the note body]"),
            "footnote should resolve to its body, got: {result}"
        );
        assert!(!result.contains("[^1]"));
    }
}
