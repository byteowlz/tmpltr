//! Markdown to Typst conversion
//!
//! Converts Markdown content to Typst markup for embedding in templates.

use pulldown_cmark::{Event, Options, Parser, Tag, TagEnd};

use crate::error::Result;

/// Convert Markdown text to Typst markup
pub fn markdown_to_typst(markdown: &str) -> Result<String> {
    let mut options = Options::empty();
    options.insert(Options::ENABLE_STRIKETHROUGH);
    options.insert(Options::ENABLE_TABLES);

    let parser = Parser::new_ext(markdown, options);
    let mut converter = TypstConverter::new();

    for event in parser {
        converter.process_event(event);
    }

    Ok(converter.finish())
}

/// Converter state machine
struct TypstConverter {
    output: String,
    list_depth: usize,
    in_code_block: bool,
    in_table: bool,
    table_alignments: Vec<pulldown_cmark::Alignment>,
    table_cell_index: usize,
}

impl TypstConverter {
    fn new() -> Self {
        Self {
            output: String::new(),
            list_depth: 0,
            in_code_block: false,
            in_table: false,
            table_alignments: Vec::new(),
            table_cell_index: 0,
        }
    }

    fn process_event(&mut self, event: Event) {
        match event {
            Event::Start(tag) => self.start_tag(tag),
            Event::End(tag) => self.end_tag(tag),
            Event::Text(text) => self.text(&text),
            Event::Code(code) => self.inline_code(&code),
            Event::SoftBreak => self.soft_break(),
            Event::HardBreak => self.hard_break(),
            Event::Rule => self.rule(),
            _ => {}
        }
    }

    fn start_tag(&mut self, tag: Tag) {
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
            Tag::CodeBlock(_) => {
                self.in_code_block = true;
                self.output.push_str("```\n");
            }
            Tag::List(Some(start)) => {
                self.list_depth += 1;
                if start != 1 {
                    // Typst doesn't support custom start numbers directly
                    // Could emit a comment or use enum with start
                }
            }
            Tag::List(None) => {
                self.list_depth += 1;
            }
            Tag::Item => {
                let indent = "  ".repeat(self.list_depth.saturating_sub(1));
                self.output.push_str(&indent);
                self.output.push_str("- ");
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
            _ => {}
        }
    }

    fn end_tag(&mut self, tag: TagEnd) {
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
                self.output.push_str("```\n");
            }
            TagEnd::List(_) => {
                self.list_depth = self.list_depth.saturating_sub(1);
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
            _ => {}
        }
    }

    fn text(&mut self, text: &str) {
        if self.in_code_block {
            self.output.push_str(text);
        } else {
            // Escape Typst special characters
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
        // Trim trailing whitespace
        while self.output.ends_with('\n') {
            self.output.pop();
        }
        self.output
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

    #[test]
    fn test_simple_text() {
        let result = markdown_to_typst("Hello world").unwrap();
        assert_eq!(result, "Hello world");
    }

    #[test]
    fn test_bold() {
        let result = markdown_to_typst("This is **bold** text").unwrap();
        assert_eq!(result, "This is *bold* text");
    }

    #[test]
    fn test_italic() {
        let result = markdown_to_typst("This is *italic* text").unwrap();
        assert_eq!(result, "This is _italic_ text");
    }

    #[test]
    fn test_heading() {
        let result = markdown_to_typst("# Heading 1\n\nContent").unwrap();
        assert!(result.starts_with("= Heading 1"));
    }

    #[test]
    fn test_list() {
        let result = markdown_to_typst("- Item 1\n- Item 2").unwrap();
        assert!(result.contains("- Item 1"));
        assert!(result.contains("- Item 2"));
    }

    #[test]
    fn test_escape() {
        let escaped = escape_typst("Price: $100 #tag");
        assert_eq!(escaped, "Price: \\$100 \\#tag");
    }
}
