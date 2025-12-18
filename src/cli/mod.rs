//! CLI interface for tmpltr
//!
//! Defines all commands and their arguments using clap.

pub mod commands;

use std::path::PathBuf;

use clap::{Args, Parser, Subcommand, ValueEnum};

/// tmpltr - Template-based document generation CLI
#[derive(Debug, Parser)]
#[command(
    name = "tmpltr",
    author,
    version,
    about = "Generate professional documents from structured data using Typst templates",
    propagate_version = true
)]
pub struct Cli {
    #[command(flatten)]
    pub common: CommonOpts,

    #[command(subcommand)]
    pub command: Command,
}

/// Common options available to all commands
#[derive(Debug, Clone, Args)]
pub struct CommonOpts {
    /// Override the config file path
    #[arg(long, value_name = "PATH", global = true)]
    pub config: Option<PathBuf>,

    /// Reduce output to only errors
    #[arg(short, long, action = clap::ArgAction::SetTrue, global = true)]
    pub quiet: bool,

    /// Increase logging verbosity (stackable)
    #[arg(short = 'v', long = "verbose", action = clap::ArgAction::Count, global = true)]
    pub verbose: u8,

    /// Enable debug logging
    #[arg(long, global = true)]
    pub debug: bool,

    /// Output machine-readable JSON
    #[arg(long, global = true)]
    pub json: bool,

    /// Disable ANSI colors in output
    #[arg(long = "no-color", global = true)]
    pub no_color: bool,

    /// Control color output
    #[arg(long, value_enum, default_value_t = ColorOption::Auto, global = true)]
    pub color: ColorOption,

    /// Do not change anything on disk
    #[arg(long = "dry-run", global = true)]
    pub dry_run: bool,
}

/// Color output option
#[derive(Debug, Clone, Copy, ValueEnum, Default)]
pub enum ColorOption {
    #[default]
    Auto,
    Always,
    Never,
}

/// Available commands
#[derive(Debug, Subcommand)]
pub enum Command {
    /// Extract content structure from template, generate TOML
    Init(InitArgs),

    /// Create content file from registered template
    New(NewArgs),

    /// Generate a self-contained example template + content pair
    Example(ExampleArgs),

    /// Compile to PDF/SVG/HTML
    Compile(CompileArgs),

    /// Get block value(s) by path or title
    Get(GetArgs),

    /// Set block value(s)
    Set(SetArgs),

    /// List editable blocks
    Blocks(BlocksArgs),

    /// Validate content against schema
    Validate(ValidateArgs),

    /// Watch file(s) and recompile on change
    Watch(WatchArgs),

    /// List available templates
    Templates(TemplatesArgs),

    /// List cached recently used documents
    Recent(RecentArgs),

    /// Manage brands (logos, fonts, colors)
    Brands {
        #[command(subcommand)]
        command: BrandsCommand,
    },

    /// Add assets (logos, templates, fonts) to tmpltr directories
    Add {
        #[command(subcommand)]
        command: AddCommand,
    },

    /// Manage configuration
    Config {
        #[command(subcommand)]
        command: ConfigCommand,
    },

    /// Generate shell completions
    Completions {
        #[arg(value_enum)]
        shell: clap_complete::Shell,
    },

    /// Create a new template with matching content file
    NewTemplate(NewTemplateArgs),
}

/// Arguments for the init command
#[derive(Debug, Clone, Args)]
pub struct InitArgs {
    /// Typst template file to parse
    pub template: PathBuf,

    /// Output content file path
    #[arg(short, long, value_name = "PATH")]
    pub output: Option<PathBuf>,

    /// Also generate JSON schema
    #[arg(long, value_name = "PATH")]
    pub schema: Option<PathBuf>,

    /// Update existing content file (migration mode)
    #[arg(long)]
    pub update: bool,

    /// Existing content file to update
    #[arg(value_name = "CONTENT", requires = "update")]
    pub content: Option<PathBuf>,

    /// Analyze all data.* access patterns for complete skeleton generation
    #[arg(long)]
    pub analyze_data: bool,
}

/// Arguments for the new command
#[derive(Debug, Clone, Args)]
pub struct NewArgs {
    /// Template name or path
    pub template: String,

    /// Output content file path
    #[arg(short, long, value_name = "PATH")]
    pub output: Option<PathBuf>,
}

/// Arguments for the compile command
#[derive(Debug, Clone, Args)]
pub struct CompileArgs {
    /// Content file to compile
    pub content: PathBuf,

    /// Output file path
    #[arg(short, long, value_name = "PATH")]
    pub output: Option<PathBuf>,

    /// Output format (pdf, svg, html)
    #[arg(long, value_name = "FORMAT")]
    pub format: Option<String>,

    /// Brand ID or path to use (overrides content file brand)
    #[arg(long, short = 'b', value_name = "BRAND")]
    pub brand: Option<String>,

    /// Include position information in output
    #[arg(long)]
    pub with_positions: bool,

    /// Enable experimental HTML output
    #[arg(long)]
    pub experimental_html: bool,

    /// Validate template + content compatibility without generating output
    #[arg(long)]
    pub check: bool,
}

/// Arguments for the get command
#[derive(Debug, Clone, Args)]
pub struct GetArgs {
    /// Path or title of the block/field to get
    pub path_or_title: String,

    /// Content file (or use 'from <selector>')
    #[arg(value_name = "FILE")]
    pub file: Option<PathBuf>,

    /// Use selector instead of file path
    #[arg(long, value_name = "SELECTOR", conflicts_with = "file")]
    pub from: Option<String>,
}

/// Arguments for the set command
#[derive(Debug, Clone, Args)]
pub struct SetArgs {
    /// Path or title of the block/field to set
    pub path_or_title: String,

    /// Content file (or use 'from <selector>')
    #[arg(value_name = "FILE")]
    pub file: Option<PathBuf>,

    /// New value (use '-' for stdin)
    #[arg(value_name = "VALUE")]
    pub value: Option<String>,

    /// Use selector instead of file path
    #[arg(long, value_name = "SELECTOR", conflicts_with = "file")]
    pub from: Option<String>,

    /// Read value from file
    #[arg(long, value_name = "PATH", conflicts_with = "value")]
    pub file_input: Option<PathBuf>,

    /// Read JSON batch from stdin
    #[arg(long, conflicts_with_all = ["value", "file_input", "path_or_title"])]
    pub batch: bool,
}

/// Arguments for the blocks command
#[derive(Debug, Clone, Args)]
pub struct BlocksArgs {
    /// Content file (or use 'from <selector>')
    #[arg(value_name = "FILE")]
    pub file: Option<PathBuf>,

    /// Use selector instead of file path
    #[arg(long, value_name = "SELECTOR", conflicts_with = "file")]
    pub from: Option<String>,
}

/// Arguments for the validate command
#[derive(Debug, Clone, Args)]
pub struct ValidateArgs {
    /// Content file to validate
    pub content: PathBuf,

    /// JSON schema file (optional, uses template-specific schema if not provided)
    #[arg(long, value_name = "PATH")]
    pub schema: Option<PathBuf>,
}

/// Arguments for the watch command
#[derive(Debug, Clone, Args)]
pub struct WatchArgs {
    /// Content file to watch
    pub content: PathBuf,

    /// Output file path
    #[arg(short, long, value_name = "PATH")]
    pub output: Option<PathBuf>,

    /// Output format (pdf, svg, html)
    #[arg(long, value_name = "FORMAT")]
    pub format: Option<String>,

    /// Brand ID or path to use (overrides content file brand)
    #[arg(long, short = 'b', value_name = "BRAND")]
    pub brand: Option<String>,

    /// Enable experimental HTML output
    #[arg(long)]
    pub experimental_html: bool,

    /// Debounce time in milliseconds
    #[arg(long, value_name = "MS")]
    pub debounce: Option<u64>,

    /// Open output in default PDF viewer after initial compile
    #[arg(long)]
    pub open: bool,
}

/// Arguments for the templates command
#[derive(Debug, Clone, Args)]
pub struct TemplatesArgs {
    /// Directory to search (defaults to config paths)
    #[arg(value_name = "PATH")]
    pub path: Option<PathBuf>,
}

/// Arguments for the recent command
#[derive(Debug, Clone, Args)]
pub struct RecentArgs {
    /// Maximum number of entries to show
    #[arg(short, long, default_value = "10")]
    pub limit: usize,
}

/// Configuration subcommands
#[derive(Debug, Subcommand)]
pub enum ConfigCommand {
    /// Show the effective configuration
    Show,

    /// Print the resolved config file path
    Path,

    /// Regenerate the default configuration file
    Reset,
}

/// Brands subcommands
#[derive(Debug, Subcommand)]
pub enum BrandsCommand {
    /// List available brands
    List(BrandsListArgs),

    /// Show details of a specific brand
    Show(BrandsShowArgs),

    /// Create a new brand directory with scaffold files
    New(BrandsNewArgs),

    /// Validate a brand configuration
    Validate(BrandsValidateArgs),
}

/// Arguments for brands list command
#[derive(Debug, Clone, Args)]
pub struct BrandsListArgs {
    /// Directory to search (defaults to config brands_dir)
    #[arg(value_name = "PATH")]
    pub path: Option<PathBuf>,
}

/// Arguments for brands show command
#[derive(Debug, Clone, Args)]
pub struct BrandsShowArgs {
    /// Brand ID or path to brand directory
    pub brand: String,

    /// Language code for localized content
    #[arg(long, short = 'l', value_name = "LANG")]
    pub lang: Option<String>,
}

/// Arguments for brands new command
#[derive(Debug, Clone, Args)]
pub struct BrandsNewArgs {
    /// Brand ID (used as directory name)
    pub id: String,

    /// Brand name
    #[arg(long, short = 'n', value_name = "NAME")]
    pub name: Option<String>,

    /// Output directory (defaults to brands_dir/<id>)
    #[arg(short, long, value_name = "PATH")]
    pub output: Option<PathBuf>,

    /// Primary color (hex code)
    #[arg(long, value_name = "COLOR")]
    pub primary_color: Option<String>,

    /// Overwrite existing brand
    #[arg(long, short = 'f')]
    pub force: bool,
}

/// Arguments for brands validate command
#[derive(Debug, Clone, Args)]
pub struct BrandsValidateArgs {
    /// Brand ID or path to brand directory/file
    pub brand: String,

    /// Check that all referenced files exist
    #[arg(long)]
    pub check_files: bool,
}

/// Add asset subcommands
#[derive(Debug, Subcommand)]
pub enum AddCommand {
    /// Add a logo to a brand directory
    Logo(AddLogoArgs),

    /// Add a template to the templates directory
    Template(AddTemplateArgs),

    /// Add a font to a brand directory
    Font(AddFontArgs),
}

/// Arguments for adding a logo
#[derive(Debug, Clone, Args)]
pub struct AddLogoArgs {
    /// Source file path
    pub source: PathBuf,

    /// Brand name (required, creates brands/<brand>/logos/)
    #[arg(long, short = 'b', value_name = "NAME")]
    pub brand: String,

    /// Output filename (defaults to source filename)
    #[arg(long, short = 'n', value_name = "NAME")]
    pub name: Option<String>,

    /// Overwrite existing file
    #[arg(long, short = 'f')]
    pub force: bool,
}

/// Arguments for adding a template
#[derive(Debug, Clone, Args)]
pub struct AddTemplateArgs {
    /// Source file path
    pub source: PathBuf,

    /// Output filename (defaults to source filename)
    #[arg(long, short = 'n', value_name = "NAME")]
    pub name: Option<String>,

    /// Overwrite existing file
    #[arg(long, short = 'f')]
    pub force: bool,
}

/// Arguments for adding a font
#[derive(Debug, Clone, Args)]
pub struct AddFontArgs {
    /// Source file path
    pub source: PathBuf,

    /// Brand name (required, creates brands/<brand>/fonts/)
    #[arg(long, short = 'b', value_name = "NAME")]
    pub brand: String,

    /// Output filename (defaults to source filename)
    #[arg(long, short = 'n', value_name = "NAME")]
    pub name: Option<String>,

    /// Overwrite existing file
    #[arg(long, short = 'f')]
    pub force: bool,
}

impl CommonOpts {
    /// Get the effective log level
    pub fn log_level(&self) -> log::LevelFilter {
        if self.quiet {
            log::LevelFilter::Off
        } else if self.debug {
            log::LevelFilter::Debug
        } else {
            match self.verbose {
                0 => log::LevelFilter::Info,
                1 => log::LevelFilter::Debug,
                _ => log::LevelFilter::Trace,
            }
        }
    }

    /// Check if colors should be used
    pub fn use_colors(&self) -> bool {
        match self.color {
            ColorOption::Always => true,
            ColorOption::Never => false,
            ColorOption::Auto => !self.no_color && atty_is_terminal(),
        }
    }
}

/// Check if stderr is a terminal
fn atty_is_terminal() -> bool {
    std::io::IsTerminal::is_terminal(&std::io::stderr())
}
/// Arguments for the example command
#[derive(Debug, Clone, Args)]
pub struct ExampleArgs {
    /// Output template path
    #[arg(long, value_name = "PATH", default_value = "example-template.typ")]
    pub template: PathBuf,

    /// Output content path
    #[arg(long, value_name = "PATH", default_value = "example-content.toml")]
    pub content: PathBuf,

    /// Overwrite existing files
    #[arg(long, default_value_t = false)]
    pub force: bool,
}

/// Arguments for the new-template command
#[derive(Debug, Clone, Args)]
pub struct NewTemplateArgs {
    /// Template name (used for filenames)
    pub name: String,

    /// Output directory (defaults to current directory)
    #[arg(short, long, value_name = "PATH")]
    pub output: Option<PathBuf>,

    /// Template description
    #[arg(long, value_name = "DESC")]
    pub description: Option<String>,

    /// Template version
    #[arg(long, value_name = "VERSION", default_value = "1.0.0")]
    pub version: String,

    /// Overwrite existing files
    #[arg(long, short = 'f')]
    pub force: bool,
}
