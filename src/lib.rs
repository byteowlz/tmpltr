//! tmpltr - Template-based document generation CLI
//!
//! This library provides the core functionality for the tmpltr CLI tool,
//! which generates professional documents from structured data using Typst templates.

pub mod brand;
pub mod cache;
pub mod cli;
pub mod config;
pub mod content;
pub mod error;
pub mod markdown;
pub mod template;
pub mod typst;

pub use error::{Error, Result};
