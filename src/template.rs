//! Template parsing for tmpltr
//!
//! Parses Typst templates to extract editable() and editable-block() markers.

use std::fs;
use std::path::{Path, PathBuf};

use regex::Regex;
use serde::{Deserialize, Serialize};

use crate::content::BlockFormat;
use crate::error::{Error, Result};

/// Information about an editable field extracted from a template
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EditableField {
    /// Field path (e.g., "quote.kunde.name")
    pub path: String,
    /// Field type (e.g., "text")
    pub field_type: String,
    /// Default value
    pub default: Option<String>,
}

/// Information about an editable block extracted from a template
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EditableBlock {
    /// Block path (e.g., "blocks.ausgangssituation")
    pub path: String,
    /// Human-readable title
    pub title: Option<String>,
    /// Content format
    pub format: BlockFormat,
    /// Default content
    pub default_content: Option<String>,
}

/// Parsed template information
#[derive(Debug, Clone)]
pub struct TemplateInfo {
    /// Template file path
    pub path: PathBuf,
    /// Template ID (derived from filename or metadata)
    pub id: String,
    /// Template description (if found)
    pub description: Option<String>,
    /// Template version (if found)
    pub version: Option<String>,
    /// Extracted editable fields
    pub fields: Vec<EditableField>,
    /// Extracted editable blocks
    pub blocks: Vec<EditableBlock>,
}

/// Extracted data access pattern from template
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DataAccess {
    /// Path being accessed (e.g., "quote.client.name")
    pub path: String,
    /// Default value if specified
    pub default: Option<String>,
}

impl TemplateInfo {
    /// Parse a Typst template file
    pub fn parse(path: impl AsRef<Path>) -> Result<Self> {
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

        Self::parse_content(path.to_path_buf(), &content)
    }

    /// Parse template content
    pub fn parse_content(path: PathBuf, content: &str) -> Result<Self> {
        let id = path
            .file_stem()
            .and_then(|s| s.to_str())
            .unwrap_or("unknown")
            .to_string();

        let fields = Self::extract_fields(content)?;
        let blocks = Self::extract_blocks(content)?;

        // Try to extract metadata from comments
        let description = Self::extract_comment_value(content, "description");
        let version = Self::extract_comment_value(content, "version");

        Ok(Self {
            path,
            id,
            description,
            version,
            fields,
            blocks,
        })
    }

    /// Extract data access patterns from template (data.*, get(data, ...), etc.)
    pub fn extract_data_access(content: &str) -> Vec<DataAccess> {
        let mut accesses = std::collections::HashSet::new();
        let mut results = Vec::new();

        // Match data.path patterns (e.g., data.quote.client.name)
        let data_re = Regex::new(r"data\.([a-zA-Z_][a-zA-Z0-9_.]*)").expect("invalid regex");
        for cap in data_re.captures_iter(content) {
            if let Some(path) = cap.get(1) {
                let path_str = path.as_str().to_string();
                if accesses.insert(path_str.clone()) {
                    results.push(DataAccess {
                        path: path_str,
                        default: None,
                    });
                }
            }
        }

        // Match get(data, "path", default: value) patterns
        let get_re = Regex::new(
            r#"get\s*\(\s*data\s*,\s*"([^"]+)"(?:\s*,\s*default:\s*(?:"([^"]+)"|([^\s,)]+)))?\s*\)"#
        ).expect("invalid regex");
        for cap in get_re.captures_iter(content) {
            if let Some(path) = cap.get(1) {
                let path_str = path.as_str().to_string();
                let default = cap.get(2).or(cap.get(3)).map(|m| m.as_str().to_string());
                if accesses.insert(path_str.clone()) {
                    results.push(DataAccess {
                        path: path_str,
                        default,
                    });
                }
            }
        }

        // Match blocks.name or data.blocks.name patterns
        let blocks_re = Regex::new(r#"blocks\.([a-zA-Z_][a-zA-Z0-9_]*)"#).expect("invalid regex");
        for cap in blocks_re.captures_iter(content) {
            if let Some(name) = cap.get(1) {
                let path_str = format!("blocks.{}", name.as_str());
                if accesses.insert(path_str.clone()) {
                    results.push(DataAccess {
                        path: path_str,
                        default: None,
                    });
                }
            }
        }

        results.sort_by(|a, b| a.path.cmp(&b.path));
        results
    }

    /// Extract editable() calls from template content
    fn extract_fields(content: &str) -> Result<Vec<EditableField>> {
        let mut fields = Vec::new();

        // Match #editable("path", type: "text", default: value)
        // This regex is simplified - a full parser would be more robust
        let re = Regex::new(
            r#"#editable\(\s*"([^"]+)"(?:\s*,\s*type:\s*"([^"]+)")?(?:\s*,\s*default:\s*(?:"([^"]+)"|([^\s,)]+)))?\s*\)"#
        ).map_err(|e| Error::Template(format!("regex error: {}", e)))?;

        for cap in re.captures_iter(content) {
            let path = cap
                .get(1)
                .map(|m| m.as_str().to_string())
                .unwrap_or_default();
            let field_type = cap
                .get(2)
                .map(|m| m.as_str().to_string())
                .unwrap_or_else(|| "text".to_string());
            let default = cap
                .get(3)
                .or_else(|| cap.get(4))
                .map(|m| m.as_str().to_string());

            fields.push(EditableField {
                path,
                field_type,
                default,
            });
        }

        Ok(fields)
    }

    /// Extract editable-block() calls from template content
    fn extract_blocks(content: &str) -> Result<Vec<EditableBlock>> {
        let mut blocks = Vec::new();

        // Match #editable-block("path", title: "Title", format: "markdown")[content]
        // This is a simplified pattern - handles common cases
        let re = Regex::new(
            r#"#editable-block\(\s*"([^"]+)"(?:\s*,\s*title:\s*"([^"]+)")?(?:\s*,\s*format:\s*"([^"]+)")?\s*\)\s*\[([^\]]*)\]"#
        ).map_err(|e| Error::Template(format!("regex error: {}", e)))?;

        for cap in re.captures_iter(content) {
            let path = cap
                .get(1)
                .map(|m| m.as_str().to_string())
                .unwrap_or_default();
            let title = cap.get(2).map(|m| m.as_str().to_string());
            let format_str = cap.get(3).map(|m| m.as_str()).unwrap_or("markdown");
            let default_content = cap.get(4).map(|m| m.as_str().trim().to_string());

            let format = match format_str {
                "typst" => BlockFormat::Typst,
                "plain" => BlockFormat::Plain,
                _ => BlockFormat::Markdown,
            };

            blocks.push(EditableBlock {
                path,
                title,
                format,
                default_content,
            });
        }

        Ok(blocks)
    }

    /// Extract a value from template comments (e.g., "// @description: ...")
    fn extract_comment_value(content: &str, key: &str) -> Option<String> {
        let pattern = format!(r"//\s*@{}:\s*(.+)", key);
        let re = Regex::new(&pattern).ok()?;
        re.captures(content)
            .and_then(|cap| cap.get(1))
            .map(|m| m.as_str().trim().to_string())
    }
}

/// Template registry for managing available templates
#[derive(Debug)]
pub struct TemplateRegistry {
    /// Search paths for templates
    search_paths: Vec<PathBuf>,
}

impl TemplateRegistry {
    /// Create a new registry with the given search paths
    pub fn new(search_paths: Vec<PathBuf>) -> Self {
        Self { search_paths }
    }

    /// Find a template by ID or path
    pub fn find(&self, name: &str) -> Result<TemplateInfo> {
        // First check if it's a direct path
        let path = PathBuf::from(name);
        if path.exists() {
            return TemplateInfo::parse(&path);
        }

        // Search in registered paths
        for search_path in &self.search_paths {
            // Try exact match
            let candidate = search_path.join(name);
            if candidate.exists() {
                return TemplateInfo::parse(&candidate);
            }

            // Try with .typ extension
            let candidate = search_path.join(format!("{}.typ", name));
            if candidate.exists() {
                return TemplateInfo::parse(&candidate);
            }
        }

        Err(Error::Template(format!("template '{}' not found", name)))
    }

    /// List all available templates
    pub fn list(&self) -> Vec<TemplateInfo> {
        let mut templates = Vec::new();

        for search_path in &self.search_paths {
            if let Ok(entries) = fs::read_dir(search_path) {
                for entry in entries.flatten() {
                    let path = entry.path();
                    if path.extension().and_then(|s| s.to_str()) == Some("typ") {
                        if let Ok(info) = TemplateInfo::parse(&path) {
                            templates.push(info);
                        }
                    }
                }
            }
        }

        templates
    }
}

/// Summary of a template for listing
#[derive(Debug, Serialize)]
pub struct TemplateSummary {
    pub id: String,
    pub file: PathBuf,
    pub description: Option<String>,
    pub version: Option<String>,
}

impl From<&TemplateInfo> for TemplateSummary {
    fn from(info: &TemplateInfo) -> Self {
        Self {
            id: info.id.clone(),
            file: info.path.clone(),
            description: info.description.clone(),
            version: info.version.clone(),
        }
    }
}

impl TemplateInfo {
    /// Generate a JSON schema for content files based on this template
    pub fn generate_schema(&self) -> serde_json::Value {
        let mut properties = serde_json::Map::new();
        let mut required = Vec::new();

        // Add meta section schema
        properties.insert(
            "meta".to_string(),
            serde_json::json!({
                "type": "object",
                "description": "Content file metadata",
                "properties": {
                    "template": {
                        "type": "string",
                        "description": "Template file path"
                    },
                    "template_id": {
                        "type": "string",
                        "description": "Template identifier"
                    },
                    "template_version": {
                        "type": "string",
                        "description": "Template version"
                    }
                },
                "required": ["template"]
            }),
        );
        required.push("meta".to_string());

        // Group fields by top-level key
        let mut field_groups: std::collections::BTreeMap<String, Vec<&EditableField>> =
            std::collections::BTreeMap::new();
        for field in &self.fields {
            let parts: Vec<&str> = field.path.split('.').collect();
            if !parts.is_empty() {
                field_groups
                    .entry(parts[0].to_string())
                    .or_default()
                    .push(field);
            }
        }

        // Add field groups
        for (group, fields) in field_groups {
            if group == "blocks" {
                continue; // Handle blocks separately
            }
            properties.insert(group.clone(), Self::build_field_schema(&fields, &group));
        }

        // Add blocks section schema
        if !self.blocks.is_empty() {
            let mut block_properties = serde_json::Map::new();
            for block in &self.blocks {
                let block_name = block.path.strip_prefix("blocks.").unwrap_or(&block.path);
                block_properties.insert(
                    block_name.to_string(),
                    serde_json::json!({
                        "type": "object",
                        "description": block.title.clone().unwrap_or_else(|| block_name.to_string()),
                        "properties": {
                            "title": {
                                "type": "string",
                                "description": "Block title"
                            },
                            "format": {
                                "type": "string",
                                "enum": ["markdown", "typst", "plain"],
                                "default": "markdown"
                            },
                            "content": {
                                "type": "string",
                                "description": "Block content"
                            }
                        }
                    }),
                );
            }
            properties.insert(
                "blocks".to_string(),
                serde_json::json!({
                    "type": "object",
                    "description": "Content blocks",
                    "properties": block_properties
                }),
            );
        }

        serde_json::json!({
            "$schema": "https://json-schema.org/draft/2020-12/schema",
            "$id": format!("https://tmpltr.dev/schemas/{}.schema.json", self.id),
            "title": format!("{} Content Schema", self.id),
            "description": self.description.clone().unwrap_or_else(|| format!("Schema for {} content files", self.id)),
            "type": "object",
            "properties": properties,
            "required": required,
            "additionalProperties": true
        })
    }

    /// Build schema for a group of fields
    fn build_field_schema(fields: &[&EditableField], prefix: &str) -> serde_json::Value {
        // Build nested object structure based on field paths
        let mut props = serde_json::Map::new();

        for field in fields {
            let relative_path = field
                .path
                .strip_prefix(&format!("{}.", prefix))
                .unwrap_or(&field.path);
            let parts: Vec<&str> = relative_path.split('.').collect();

            Self::insert_field_schema(&mut props, &parts, field);
        }

        if props.len() == 1
            && props
                .values()
                .next()
                .map(|v| v.is_string())
                .unwrap_or(false)
        {
            // Single field, return directly
            props.into_iter().next().map(|(_, v)| v).unwrap()
        } else {
            serde_json::json!({
                "type": "object",
                "properties": props
            })
        }
    }

    /// Insert a field into the nested schema structure
    fn insert_field_schema(
        props: &mut serde_json::Map<String, serde_json::Value>,
        parts: &[&str],
        field: &EditableField,
    ) {
        if parts.is_empty() {
            return;
        }

        let key = parts[0].to_string();

        if parts.len() == 1 {
            // Leaf field
            let mut schema = serde_json::Map::new();
            schema.insert(
                "type".to_string(),
                serde_json::Value::String("string".to_string()),
            );
            schema.insert(
                "description".to_string(),
                serde_json::Value::String(format!("Field: {}", field.path)),
            );
            if let Some(ref default) = field.default {
                schema.insert(
                    "default".to_string(),
                    serde_json::Value::String(default.clone()),
                );
            }
            props.insert(key, serde_json::Value::Object(schema));
        } else {
            // Nested field
            let entry = props.entry(key.clone()).or_insert_with(|| {
                serde_json::json!({
                    "type": "object",
                    "properties": {}
                })
            });

            if let Some(nested_props) = entry.get_mut("properties").and_then(|p| p.as_object_mut())
            {
                Self::insert_field_schema(nested_props, &parts[1..], field);
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const SAMPLE_TEMPLATE: &str = r#"
// @description: Test template for tmpltr
// @version: 1.0.0

#import "@local/tmpltr-lib:1.0.0": editable, editable-block

#editable("quote.number", type: "text", default: "2025-001")
#editable("quote.title", type: "text", default: "Project Title")
#editable("quote.client.name", type: "text")

#editable-block("blocks.intro", title: "Introduction", format: "markdown")[
  This is the introduction text.
]
"#;

    #[test]
    fn test_parse_fields() {
        let info = TemplateInfo::parse_content(PathBuf::from("test.typ"), SAMPLE_TEMPLATE).unwrap();

        assert_eq!(info.fields.len(), 3);
        assert_eq!(info.fields[0].path, "quote.number");
        assert_eq!(info.fields[0].default, Some("2025-001".to_string()));
    }

    #[test]
    fn test_parse_blocks() {
        let info = TemplateInfo::parse_content(PathBuf::from("test.typ"), SAMPLE_TEMPLATE).unwrap();

        assert_eq!(info.blocks.len(), 1);
        assert_eq!(info.blocks[0].path, "blocks.intro");
        assert_eq!(info.blocks[0].title, Some("Introduction".to_string()));
        assert_eq!(info.blocks[0].format, BlockFormat::Markdown);
    }

    #[test]
    fn test_extract_metadata() {
        let info = TemplateInfo::parse_content(PathBuf::from("test.typ"), SAMPLE_TEMPLATE).unwrap();

        assert_eq!(
            info.description,
            Some("Test template for tmpltr".to_string())
        );
        assert_eq!(info.version, Some("1.0.0".to_string()));
    }
}
