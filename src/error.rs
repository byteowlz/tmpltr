//! Error types for tmpltr

use std::path::PathBuf;
use thiserror::Error;

/// Result type alias using tmpltr's Error type
pub type Result<T> = std::result::Result<T, Error>;

/// Main error type for tmpltr
#[derive(Debug, Error)]
pub enum Error {
    /// Configuration errors
    #[error("configuration error: {0}")]
    Config(String),

    /// Content file errors
    #[error("content error: {0}")]
    Content(String),

    /// Brand parsing/validation errors
    #[error("brand error: {0}")]
    Brand(String),

    /// Template parsing errors
    #[error("template error: {0}")]
    Template(String),

    /// Path not found in content
    #[error("path not found: {path}")]
    PathNotFound { path: String },

    /// Ambiguous title (multiple matches)
    #[error("ambiguous title '{title}': matches {matches:?}")]
    AmbiguousTitle { title: String, matches: Vec<String> },

    /// Block title not found
    #[error("block with title '{title}' not found")]
    TitleNotFound { title: String },

    /// Typst compilation error
    #[error("typst compilation failed: {message}")]
    TypstCompilation {
        message: String,
        details: Option<String>,
    },

    /// File not found
    #[error("file not found: {}", path.display())]
    FileNotFound { path: PathBuf },

    /// IO error
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    /// TOML parsing error
    #[error("TOML parse error: {0}")]
    TomlParse(#[from] toml::de::Error),

    /// TOML serialization error
    #[error("TOML serialization error: {0}")]
    TomlSerialize(#[from] toml::ser::Error),

    /// JSON error
    #[error("JSON error: {0}")]
    Json(#[from] serde_json::Error),

    /// Cache error
    #[error("cache error: {0}")]
    Cache(String),

    /// No recent document in cache
    #[error("no recent document found in cache")]
    NoRecentDocument,

    /// Validation error
    #[error("validation error: {0}")]
    Validation(String),

    /// Watch error
    #[error("watch error: {0}")]
    Watch(String),

    /// Generic error wrapper
    #[error(transparent)]
    Other(#[from] anyhow::Error),
}

impl Error {
    /// Get the exit code for this error type
    pub fn exit_code(&self) -> i32 {
        match self {
            Error::Config(_) | Error::Validation(_) => 1,
            Error::TypstCompilation { .. } => 2,
            Error::PathNotFound { .. }
            | Error::TitleNotFound { .. }
            | Error::AmbiguousTitle { .. }
            | Error::FileNotFound { .. } => 1,
            Error::Io(_)
            | Error::TomlParse(_)
            | Error::TomlSerialize(_)
            | Error::Json(_)
            | Error::Content(_)
            | Error::Brand(_)
            | Error::Template(_)
            | Error::Cache(_)
            | Error::NoRecentDocument
            | Error::Watch(_) => 1,
            Error::Other(_) => 10,
        }
    }

    /// Get the error kind as a string for JSON output
    pub fn kind(&self) -> &'static str {
        match self {
            Error::Config(_) => "config_error",
            Error::Content(_) => "content_error",
            Error::Brand(_) => "brand_error",
            Error::Template(_) => "template_error",
            Error::PathNotFound { .. } => "path_not_found",
            Error::AmbiguousTitle { .. } => "ambiguous_title",
            Error::TitleNotFound { .. } => "title_not_found",
            Error::TypstCompilation { .. } => "typst_error",
            Error::FileNotFound { .. } => "file_not_found",
            Error::Io(_) => "io_error",
            Error::TomlParse(_) => "toml_parse_error",
            Error::TomlSerialize(_) => "toml_serialize_error",
            Error::Json(_) => "json_error",
            Error::Cache(_) => "cache_error",
            Error::NoRecentDocument => "no_recent_document",
            Error::Validation(_) => "validation_error",
            Error::Watch(_) => "watch_error",
            Error::Other(_) => "internal_error",
        }
    }
}
