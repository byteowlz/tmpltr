//! Content model for tmpltr
//!
//! Handles TOML content files with blocks, fields, and various formats.

use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

use crate::error::{Error, Result};

/// Content file metadata
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContentMeta {
    /// Template file or name (may be relative or absolute)
    pub template: String,
    /// Resolved template path (absolute, relative to content file)
    #[serde(skip)]
    pub resolved_template: Option<PathBuf>,
    /// Template identifier
    pub template_id: Option<String>,
    /// Template version
    pub template_version: Option<String>,
    /// When the content file was generated
    pub generated_at: Option<DateTime<Utc>>,
}

/// Block format type
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Default)]
#[serde(rename_all = "lowercase")]
pub enum BlockFormat {
    /// Markdown format (converted to Typst)
    #[default]
    Markdown,
    /// Raw Typst content
    Typst,
    /// Plain text (escaped for Typst)
    Plain,
}

impl BlockFormat {
    pub fn as_str(&self) -> &'static str {
        match self {
            BlockFormat::Markdown => "markdown",
            BlockFormat::Typst => "typst",
            BlockFormat::Plain => "plain",
        }
    }
}

/// Block type
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Default)]
#[serde(rename_all = "lowercase")]
pub enum BlockType {
    /// Single text content
    #[default]
    Text,
    /// Table with columns and rows
    Table,
}

impl BlockType {
    pub fn as_str(&self) -> &'static str {
        match self {
            BlockType::Text => "text",
            BlockType::Table => "table",
        }
    }
}

/// A content block
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContentBlock {
    /// Human-readable title
    pub title: Option<String>,
    /// Format for text content
    #[serde(default)]
    pub format: BlockFormat,
    /// Block type
    #[serde(default, rename = "type")]
    pub block_type: BlockType,
    /// Text content (for text blocks)
    pub content: Option<String>,
    /// Table columns (for table blocks)
    pub columns: Option<Vec<String>>,
    /// Table rows (for table blocks)
    pub rows: Option<Vec<Vec<String>>>,
}

impl ContentBlock {
    /// Create a new text block
    pub fn text(title: impl Into<String>, content: impl Into<String>) -> Self {
        Self {
            title: Some(title.into()),
            format: BlockFormat::Markdown,
            block_type: BlockType::Text,
            content: Some(content.into()),
            columns: None,
            rows: None,
        }
    }

    /// Create a new table block
    pub fn table(title: impl Into<String>, columns: Vec<String>, rows: Vec<Vec<String>>) -> Self {
        Self {
            title: Some(title.into()),
            format: BlockFormat::Plain,
            block_type: BlockType::Table,
            content: None,
            columns: Some(columns),
            rows: Some(rows),
        }
    }
}

/// A parsed content file
#[derive(Debug, Clone)]
pub struct ContentFile {
    /// File path
    pub path: PathBuf,
    /// Metadata section
    pub meta: ContentMeta,
    /// Raw TOML data for flexible access
    pub data: toml::Value,
    /// Extracted blocks index
    blocks_index: HashMap<String, BlockInfo>,
}

/// Information about a block for indexing
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BlockInfo {
    /// Block ID (path)
    pub id: String,
    /// Block path
    pub path: String,
    /// Human-readable title
    pub title: Option<String>,
    /// Whether this is a block or field
    pub kind: BlockKind,
    /// Format (for text blocks)
    pub format: Option<String>,
    /// Type (text, table, etc.)
    pub block_type: Option<String>,
}

/// Kind of editable item
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum BlockKind {
    /// A content block (under [blocks.*])
    Block,
    /// A simple field
    Field,
}

impl BlockKind {
    pub fn as_str(&self) -> &'static str {
        match self {
            BlockKind::Block => "block",
            BlockKind::Field => "field",
        }
    }
}

impl ContentFile {
    /// Load a content file from disk
    pub fn load(path: impl AsRef<Path>) -> Result<Self> {
        let path = path.as_ref();
        let content = fs::read_to_string(path).map_err(|e| {
            if e.kind() == std::io::ErrorKind::NotFound {
                Error::FileNotFound {
                    path: path.to_path_buf(),
                }
            } else {
                Error::Io(e)
            }
        })?;

        Self::parse(path.to_path_buf(), &content)
    }

    /// Parse content from a string
    pub fn parse(path: PathBuf, content: &str) -> Result<Self> {
        let data: toml::Value = toml::from_str(content)?;

        let mut meta = Self::extract_meta(&data)?;

        // Resolve template path relative to content file
        let content_dir = path.parent().unwrap_or(Path::new("."));
        let template_path = PathBuf::from(&meta.template);

        if template_path.is_absolute() {
            meta.resolved_template = Some(template_path);
        } else {
            // Relative path - resolve relative to content file location
            let resolved = content_dir.join(&template_path);
            if resolved.exists() {
                meta.resolved_template = Some(resolved.canonicalize().unwrap_or(resolved));
            } else {
                // Keep as is for search in template directories
                meta.resolved_template = Some(resolved);
            }
        }

        let mut file = Self {
            path,
            meta,
            data,
            blocks_index: HashMap::new(),
        };

        file.build_index();
        Ok(file)
    }

    /// Extract metadata from TOML
    fn extract_meta(data: &toml::Value) -> Result<ContentMeta> {
        let meta_table = data
            .get("meta")
            .ok_or_else(|| Error::Content("missing [meta] section in content file".to_string()))?;

        let template = meta_table
            .get("template")
            .and_then(|v| v.as_str())
            .ok_or_else(|| Error::Content("missing meta.template field".to_string()))?
            .to_string();

        let template_id = meta_table
            .get("template_id")
            .and_then(|v| v.as_str())
            .map(|s| s.to_string());

        let template_version = meta_table
            .get("template_version")
            .and_then(|v| v.as_str())
            .map(|s| s.to_string());

        let generated_at = meta_table
            .get("generated_at")
            .and_then(|v| v.as_str())
            .and_then(|s| DateTime::parse_from_rfc3339(s).ok())
            .map(|dt| dt.with_timezone(&Utc));

        Ok(ContentMeta {
            template,
            resolved_template: None,
            template_id,
            template_version,
            generated_at,
        })
    }

    /// Build the blocks index
    fn build_index(&mut self) {
        self.blocks_index.clear();

        // Index blocks section
        if let Some(blocks) = self.data.get("blocks").and_then(|v| v.as_table()) {
            for (name, value) in blocks {
                let path = format!("blocks.{}", name);
                let title = value
                    .get("title")
                    .and_then(|v| v.as_str())
                    .map(|s| s.to_string());
                let format = value
                    .get("format")
                    .and_then(|v| v.as_str())
                    .map(|s| s.to_string());
                let block_type = value
                    .get("type")
                    .and_then(|v| v.as_str())
                    .map(|s| s.to_string());

                self.blocks_index.insert(
                    path.clone(),
                    BlockInfo {
                        id: path.clone(),
                        path,
                        title,
                        kind: BlockKind::Block,
                        format,
                        block_type,
                    },
                );
            }
        }

        // Index other fields (quote, etc.) recursively
        self.index_fields("", &self.data.clone());
    }

    /// Recursively index fields
    fn index_fields(&mut self, prefix: &str, value: &toml::Value) {
        if let Some(table) = value.as_table() {
            for (key, val) in table {
                // Skip meta and blocks (handled separately)
                if prefix.is_empty() && (key == "meta" || key == "blocks") {
                    continue;
                }

                let path = if prefix.is_empty() {
                    key.clone()
                } else {
                    format!("{}.{}", prefix, key)
                };

                if val.is_table() {
                    self.index_fields(&path, val);
                } else {
                    self.blocks_index.insert(
                        path.clone(),
                        BlockInfo {
                            id: path.clone(),
                            path,
                            title: None,
                            kind: BlockKind::Field,
                            format: None,
                            block_type: None,
                        },
                    );
                }
            }
        }
    }

    /// Get a value by path
    pub fn get(&self, path: &str) -> Option<&toml::Value> {
        let parts: Vec<&str> = path.split('.').collect();
        let mut current = &self.data;

        for part in parts {
            current = current.get(part)?;
        }

        Some(current)
    }

    /// Get block content by path
    pub fn get_content(&self, path: &str) -> Result<String> {
        let value = self.get(path).ok_or_else(|| Error::PathNotFound {
            path: path.to_string(),
        })?;

        // If it's a block, get the content field
        if let Some(content) = value.get("content").and_then(|v| v.as_str()) {
            return Ok(content.to_string());
        }

        // Otherwise return the value as string
        match value {
            toml::Value::String(s) => Ok(s.clone()),
            toml::Value::Integer(i) => Ok(i.to_string()),
            toml::Value::Float(f) => Ok(f.to_string()),
            toml::Value::Boolean(b) => Ok(b.to_string()),
            _ => Ok(value.to_string()),
        }
    }

    /// Get block info by path
    pub fn get_block_info(&self, path: &str) -> Option<&BlockInfo> {
        self.blocks_index.get(path)
    }

    /// Find block by title
    pub fn find_by_title(&self, title: &str) -> Result<&BlockInfo> {
        let matches: Vec<&BlockInfo> = self
            .blocks_index
            .values()
            .filter(|b| b.title.as_deref() == Some(title))
            .collect();

        match matches.len() {
            0 => Err(Error::TitleNotFound {
                title: title.to_string(),
            }),
            1 => Ok(matches[0]),
            _ => Err(Error::AmbiguousTitle {
                title: title.to_string(),
                matches: matches.iter().map(|b| b.path.clone()).collect(),
            }),
        }
    }

    /// Resolve a path-or-title to a path
    pub fn resolve_path(&self, path_or_title: &str) -> Result<String> {
        // First try as exact path
        if self.blocks_index.contains_key(path_or_title) {
            return Ok(path_or_title.to_string());
        }

        // Try as title
        let info = self.find_by_title(path_or_title)?;
        Ok(info.path.clone())
    }

    /// List all blocks and fields
    pub fn list_blocks(&self) -> Vec<&BlockInfo> {
        self.blocks_index.values().collect()
    }

    /// Get the raw TOML data
    pub fn as_toml(&self) -> &toml::Value {
        &self.data
    }

    /// Get the effective template path (resolved relative to content file)
    pub fn template_path(&self) -> &Path {
        self.meta
            .resolved_template
            .as_ref()
            .map(|p| p.as_path())
            .unwrap_or(Path::new(&self.meta.template))
    }
}

/// Builder for creating new content files
#[derive(Debug)]
pub struct ContentBuilder {
    template: String,
    template_id: Option<String>,
    template_version: Option<String>,
    data: toml::map::Map<String, toml::Value>,
    blocks: toml::map::Map<String, toml::Value>,
}

impl ContentBuilder {
    /// Create a new content builder
    pub fn new(template: impl Into<String>) -> Self {
        Self {
            template: template.into(),
            template_id: None,
            template_version: None,
            data: toml::map::Map::new(),
            blocks: toml::map::Map::new(),
        }
    }

    /// Set template ID
    pub fn template_id(mut self, id: impl Into<String>) -> Self {
        self.template_id = Some(id.into());
        self
    }

    /// Set template version
    pub fn template_version(mut self, version: impl Into<String>) -> Self {
        self.template_version = Some(version.into());
        self
    }

    /// Add a field at a path
    pub fn field(mut self, path: &str, value: toml::Value) -> Self {
        let parts: Vec<&str> = path.split('.').collect();
        Self::insert_nested(&mut self.data, &parts, value);
        self
    }

    /// Add a block
    pub fn block(
        mut self,
        name: &str,
        title: impl Into<String>,
        format: BlockFormat,
        content: impl Into<String>,
    ) -> Self {
        let mut block = toml::map::Map::new();
        block.insert("title".to_string(), toml::Value::String(title.into()));
        block.insert(
            "format".to_string(),
            toml::Value::String(format.as_str().to_string()),
        );
        block.insert("content".to_string(), toml::Value::String(content.into()));
        self.blocks
            .insert(name.to_string(), toml::Value::Table(block));
        self
    }

    /// Add a table block
    pub fn table_block(
        mut self,
        name: &str,
        title: impl Into<String>,
        columns: Vec<String>,
        rows: Vec<Vec<String>>,
    ) -> Self {
        let mut block = toml::map::Map::new();
        block.insert("title".to_string(), toml::Value::String(title.into()));
        block.insert("type".to_string(), toml::Value::String("table".to_string()));
        block.insert(
            "columns".to_string(),
            toml::Value::Array(columns.into_iter().map(toml::Value::String).collect()),
        );
        block.insert(
            "rows".to_string(),
            toml::Value::Array(
                rows.into_iter()
                    .map(|row| {
                        toml::Value::Array(row.into_iter().map(toml::Value::String).collect())
                    })
                    .collect(),
            ),
        );
        self.blocks
            .insert(name.to_string(), toml::Value::Table(block));
        self
    }

    /// Insert a value at a nested path
    fn insert_nested(
        map: &mut toml::map::Map<String, toml::Value>,
        parts: &[&str],
        value: toml::Value,
    ) {
        if parts.is_empty() {
            return;
        }

        if parts.len() == 1 {
            map.insert(parts[0].to_string(), value);
            return;
        }

        let entry = map
            .entry(parts[0].to_string())
            .or_insert_with(|| toml::Value::Table(toml::map::Map::new()));

        if let toml::Value::Table(nested) = entry {
            Self::insert_nested(nested, &parts[1..], value);
        }
    }

    /// Build the content file
    pub fn build(self) -> Result<String> {
        let mut root = toml::map::Map::new();

        // Build meta section
        let mut meta = toml::map::Map::new();
        meta.insert("template".to_string(), toml::Value::String(self.template));
        if let Some(id) = self.template_id {
            meta.insert("template_id".to_string(), toml::Value::String(id));
        }
        if let Some(version) = self.template_version {
            meta.insert("template_version".to_string(), toml::Value::String(version));
        }
        meta.insert(
            "generated_at".to_string(),
            toml::Value::String(Utc::now().to_rfc3339()),
        );
        root.insert("meta".to_string(), toml::Value::Table(meta));

        // Add data sections
        for (key, value) in self.data {
            root.insert(key, value);
        }

        // Add blocks section
        if !self.blocks.is_empty() {
            root.insert("blocks".to_string(), toml::Value::Table(self.blocks));
        }

        let content = toml::to_string_pretty(&toml::Value::Table(root))?;
        Ok(content)
    }
}

/// Fill a content file from JSON data
/// 
/// This takes a base content structure (or creates one from a template) and fills it
/// with values from a JSON object.
pub fn fill_from_json(
    template_path: impl AsRef<Path>,
    json_data: &serde_json::Value,
) -> Result<ContentFile> {
    // First, create a base content file from the template
    let template = crate::template::TemplateInfo::parse(&template_path)?;
    let mut builder = ContentBuilder::new(&template_path.as_ref().display().to_string())
        .template_id(&template.id);

    if let Some(version) = &template.version {
        builder = builder.template_version(version);
    }

    // Add fields from editable() calls with defaults
    for field in &template.fields {
        let value = field
            .default
            .clone()
            .map(toml::Value::String)
            .unwrap_or_else(|| toml::Value::String(format!("<{ }>", field.path)));
        builder = builder.field(&field.path, value);
    }

    // Add blocks from editable-block() calls
    for block in &template.blocks {
        let title = block.title.clone().unwrap_or_else(|| block.path.clone());
        let content = block.default_content.clone().unwrap_or_default();
        let name = block.path.strip_prefix("blocks.").unwrap_or(&block.path);
        builder = builder.block(name, title, block.format, content);
    }

    // Also add data access patterns that weren't in editable() calls
    let template_content = fs::read_to_string(&template_path)?;
    let data_accesses = crate::template::TemplateInfo::extract_data_access(&template_content);
    let existing_paths: std::collections::HashSet<_> =
        template.fields.iter().map(|f| &f.path).collect();

    for access in data_accesses {
        if access.path.starts_with("blocks.") {
            continue; // Blocks handled separately
        }
        if existing_paths.contains(&access.path) {
            continue; // Already added
        }
        let value = access
            .default
            .clone()
            .map(toml::Value::String)
            .unwrap_or_else(|| toml::Value::String(format!("<{}>", access.path)));
        builder = builder.field(&access.path, value);
    }

    // Build the TOML string
    let toml_str = builder.build()?;

    // Parse it into a TOML value
    let mut data: toml::Value = toml::from_str(&toml_str)?;

    // Now merge the JSON data into the TOML structure
    merge_json_into_toml(&mut data, json_data)?;

    // Create a temporary path for the filled content
    let temp_path = std::env::temp_dir().join(format!("tmpltr_fill_{}.toml", std::process::id()));

    // Build the ContentFile manually
    let meta = ContentMeta {
        template: template_path.as_ref().display().to_string(),
        resolved_template: Some(template_path.as_ref().to_path_buf()),
        template_id: Some(template.id.clone()),
        template_version: template.version.clone(),
        generated_at: Some(Utc::now()),
    };

    // Create the content file
    let mut file = ContentFile {
        path: temp_path,
        meta,
        data,
        blocks_index: HashMap::new(),
    };

    file.build_index();
    Ok(file)
}

/// Merge JSON data into a TOML structure
fn merge_json_into_toml(toml_data: &mut toml::Value, json_data: &serde_json::Value) -> Result<()> {
    match json_data {
        serde_json::Value::Object(map) => {
            for (key, json_val) in map {
                merge_value_at_path(toml_data, key, json_val)?;
            }
            Ok(())
        }
        _ => Err(Error::Content(
            "JSON data must be an object at root level".to_string(),
        )),
    }
}

/// Merge a JSON value at a specific path in the TOML structure
fn merge_value_at_path(
    toml_data: &mut toml::Value,
    path: &str,
    json_val: &serde_json::Value,
) -> Result<()> {
    let parts: Vec<&str> = path.split('.').collect();

    // Special handling for meta fields
    if parts[0] == "meta" {
        if parts.len() >= 2 {
            if let Some(meta) = toml_data.get_mut("meta") {
                if let Some(meta_table) = meta.as_table_mut() {
                    let value = json_to_toml_value(json_val)?;
                    meta_table.insert(parts[1..].join("."), value);
                }
            }
        }
        return Ok(());
    }

    // Navigate/create the path
    let mut current = toml_data;

    for (i, part) in parts.iter().enumerate() {
        if i == parts.len() - 1 {
            // Last part - set the value
            let value = json_to_toml_value(json_val)?;

            if let Some(table) = current.as_table_mut() {
                table.insert(part.to_string(), value);
            }
            break;
        }

        // Navigate deeper
        if let Some(table) = current.as_table_mut() {
            current = table
                .entry(part.to_string())
                .or_insert_with(|| toml::Value::Table(toml::map::Map::new()));
        } else {
            return Err(Error::Content(format!(
                "cannot navigate into non-table at '{}'",
                part
            )));
        }
    }

    Ok(())
}

/// Convert a JSON value to a TOML value
fn json_to_toml_value(json: &serde_json::Value) -> Result<toml::Value> {
    match json {
        serde_json::Value::Null => Ok(toml::Value::String("".to_string())),
        serde_json::Value::Bool(b) => Ok(toml::Value::Boolean(*b)),
        serde_json::Value::Number(n) => {
            if let Some(i) = n.as_i64() {
                Ok(toml::Value::Integer(i))
            } else if let Some(f) = n.as_f64() {
                Ok(toml::Value::Float(f))
            } else {
                Ok(toml::Value::String(n.to_string()))
            }
        }
        serde_json::Value::String(s) => Ok(toml::Value::String(s.clone())),
        serde_json::Value::Array(arr) => {
            let values: Result<Vec<_>> = arr.iter().map(json_to_toml_value).collect();
            Ok(toml::Value::Array(values?))
        }
        serde_json::Value::Object(obj) => {
            let mut map = toml::map::Map::new();
            for (k, v) in obj {
                map.insert(k.clone(), json_to_toml_value(v)?);
            }
            Ok(toml::Value::Table(map))
        }
    }
}

/// Apply JSON data overrides to an existing content file
pub fn apply_json_overrides(
    content: &mut ContentFile,
    json_data: &serde_json::Value,
) -> Result<()> {
    match json_data {
        serde_json::Value::Object(map) => {
            for (key, json_val) in map {
                merge_value_at_path(&mut content.data, key, json_val)?;
            }
            content.build_index();
            Ok(())
        }
        _ => Err(Error::Content(
            "JSON data must be an object at root level".to_string(),
        )),
    }
}

/// Serialize a content file to JSON
pub fn to_json(content: &ContentFile) -> Result<serde_json::Value> {
    serde_json::to_value(&content.data).map_err(|e| Error::Content(e.to_string()))
}

#[cfg(test)]
mod tests {
    use super::*;

    const SAMPLE_CONTENT: &str = r#"
[meta]
template = "test-template"
template_id = "test"
template_version = "1.0.0"
generated_at = "2025-12-08T10:00:00Z"

[quote]
number = "2025-001"
title = "Test Project"

[quote.client]
name = "Test Client"

[blocks.intro]
title = "Introduction"
format = "markdown"
content = "This is the **introduction**."
"#;

    #[test]
    fn test_parse_content() {
        let file = ContentFile::parse(PathBuf::from("test.toml"), SAMPLE_CONTENT).unwrap();
        assert_eq!(file.meta.template, "test-template");
        assert_eq!(file.meta.template_id, Some("test".to_string()));
    }

    #[test]
    fn test_get_value() {
        let file = ContentFile::parse(PathBuf::from("test.toml"), SAMPLE_CONTENT).unwrap();
        let value = file.get("quote.number").unwrap();
        assert_eq!(value.as_str(), Some("2025-001"));
    }

    #[test]
    fn test_get_content() {
        let file = ContentFile::parse(PathBuf::from("test.toml"), SAMPLE_CONTENT).unwrap();
        let content = file.get_content("blocks.intro").unwrap();
        assert_eq!(content, "This is the **introduction**.");
    }

    #[test]
    fn test_find_by_title() {
        let file = ContentFile::parse(PathBuf::from("test.toml"), SAMPLE_CONTENT).unwrap();
        let info = file.find_by_title("Introduction").unwrap();
        assert_eq!(info.path, "blocks.intro");
    }

    #[test]
    fn test_content_builder() {
        let content = ContentBuilder::new("test-template")
            .template_id("test")
            .field("quote.number", toml::Value::String("2025-001".to_string()))
            .block(
                "intro",
                "Introduction",
                BlockFormat::Markdown,
                "Hello **world**",
            )
            .build()
            .unwrap();

        assert!(content.contains("template = \"test-template\""));
        assert!(content.contains("Introduction"));
    }
}
