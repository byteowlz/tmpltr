# tmpltr

Template-based document generation CLI. Generate professional documents (quotes, invoices, reports) from structured data using Typst templates.

## Features

- Separates **content** (TOML + Markdown) from **templates** (Typst)
- Compiles to **PDF**, **SVG**, or experimental **HTML** via Typst
- **JSON pipeline**: pipe JSON data directly into PDF output (no intermediate files)
- **JSON schema** generation for every template (validation, IDE completion, agent tooling)
- **Granular read/write** access to content blocks via stable paths and titles
- **File watching** for live preview integration
- **Document cache** for ergonomic commands like `from last`
- **JSON output** for AI agent and programmatic use

## Installation

```bash
cargo install --path .
```

Requires [Typst](https://typst.app/) to be installed and available in PATH.

## Quick Start

### JSON Pipeline (fastest path)

```bash
# Pipe JSON directly to PDF -- no intermediate files
echo '{"seller":{"company":"Acme"},"buyer":{"name":"Globex"},"items":[{"description":"Consulting","qty":10,"price":150}]}' \
  | tmpltr pipe invoice -o invoice.pdf

# From a JSON file
tmpltr pipe invoice -d order.json -o invoice.pdf

# With brand
tmpltr pipe invoice -d order.json --brand mycompany -o invoice.pdf

# See what fields a template expects
tmpltr schema invoice
```

### Traditional Workflow

```bash
# Create content from a template
tmpltr new invoice -o invoice.toml

# Edit content
tmpltr set invoice.toml seller.company "Acme Inc"

# Compile to PDF
tmpltr compile invoice.toml -o invoice.pdf

# Override fields at compile time with JSON
tmpltr compile invoice.toml --data '{"buyer":{"name":"Special Client"}}' -o special.pdf

# Watch for changes
tmpltr watch invoice.toml -o invoice.pdf --open
```

### Fill from JSON (hybrid)

```bash
# Create editable TOML from JSON data
tmpltr fill invoice -d customer.json -o invoice.toml

# Edit the TOML, then compile
vim invoice.toml
tmpltr compile invoice.toml -o invoice.pdf
```

## CLI Commands

```
tmpltr <COMMAND> [OPTIONS]

COMMANDS:
    init           Extract content structure from template, generate TOML
    new            Create content file from registered template
    fill           Fill template with JSON data to create content file
    pipe           Pipe JSON data through template directly to PDF
    schema         Generate JSON schema for a template
    compile        Compile to PDF/SVG/HTML (supports --data for JSON overrides)
    get            Get block value(s) by path or title
    set            Set block value(s)
    blocks         List editable blocks
    validate       Validate content against schema
    watch          Watch file(s) and recompile on change
    templates      List available templates
    recent         List cached recently used documents
    brands         Manage brands (logos, fonts, colors)
    add            Add assets (logos, templates, fonts) to tmpltr directories
    config         Manage configuration
    new-template   Create a new template with matching content file
    completions    Generate shell completions
```

### Global Options

- `-q, --quiet` - Reduce output to only errors
- `-v, --verbose` - Increase logging verbosity (stackable)
- `--json` - Output machine-readable JSON
- `--dry-run` - Do not change anything on disk
- `--config <PATH>` - Override config file path

## Content Model

Content files use TOML with optional Markdown blocks:

```toml
[meta]
template = "byteowlz-angebot"
template_id = "byteowlz-angebot"
template_version = "1.0.0"
generated_at = "2025-12-08T10:00:00Z"

[quote]
number = "2025-001"
title = "Project Title"

[quote.client]
name = "Client Name"

[blocks.intro]
title = "Introduction"
format = "markdown"
content = """
This is the **introduction** section.
"""

[blocks.timeline]
title = "Timeline"
type = "table"
columns = ["Phase", "Duration"]
rows = [["Phase 1", "3 months"]]
```

### Block Formats

- `markdown` (default) - Markdown converted to Typst
- `typst` - Raw Typst content
- `plain` - Plain text, escaped for Typst

### Block Types

- `text` (default) - Single text content
- `table` - Table with columns and rows

## Brands

Brand definitions live in `brand.toml` files inside each brand directory. They cover colors, logos, typography, and contact details with localized text that falls back to the configured default language. See `examples/brand/brand.toml` for a minimal, German/English-ready example.

## Template Development

Templates use the tmpltr helper library:

```typst
#import "tmpltr-lib.typ": editable, editable-block, tmpltr-data, get, md

#let data = tmpltr-data()

// Render an editable field
#editable("quote.number", get(data, "quote.number"))

// Render an editable block
#editable-block("blocks.intro", title: "Introduction", format: "markdown")[
  #md(get(data, "blocks.intro.content"))
]
```

### Template Markers

- `#editable(id, value, type: "text")` - Mark a simple field as editable
- `#editable-block(id, title: "...", format: "markdown")[content]` - Mark a content block as editable

These markers enable:
- Content extraction via `tmpltr init`
- Position tracking for frontends (with `--with-positions`)

## Configuration

Config file location: `$XDG_CONFIG_HOME/tmpltr/config.toml`

```toml
[paths]
templates_dir = "$XDG_DATA_HOME/tmpltr/templates"
schemas_dir = "$XDG_DATA_HOME/tmpltr/schemas"
cache_dir = "$XDG_CACHE_HOME/tmpltr"

[typst]
binary = ""  # empty = use PATH
font_paths = []

[output]
format = "pdf"
watch_debounce_ms = 300

[experimental]
html = false
```

## Exit Codes

- `0` - Success
- `1` - User/config/validation error
- `2` - Typst compilation error
- `>=10` - Internal/unexpected errors

## Development

```bash
# Build
cargo build

# Run tests
cargo test

# Check code
cargo clippy --all-targets --all-features

# Format
cargo fmt
```

## Project Structure

```
src/
  lib.rs          # Library entry point
  main.rs         # CLI entry point
  cli/
    mod.rs        # CLI argument definitions
    commands.rs   # Command implementations
  cache.rs        # Document cache
  config.rs       # Configuration management
  content.rs      # Content model and parsing
  error.rs        # Error types
  markdown.rs     # Markdown to Typst conversion
  template.rs     # Template parsing
  typst.rs        # Typst compiler interface
```

## License

MIT
