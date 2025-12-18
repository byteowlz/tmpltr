//! Typst compilation interface
//!
//! Handles invoking the Typst compiler with proper arguments and error handling.

use std::env;
use std::path::{Path, PathBuf};
use std::process::Command;

use serde::{Deserialize, Serialize};

use crate::config::AppConfig;
use crate::content::ContentFile;
use crate::error::{Error, Result};
use crate::markdown::markdown_to_typst;

/// Output format for compilation
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum OutputFormat {
    #[default]
    Pdf,
    Svg,
    Html,
}

impl OutputFormat {
    /// Parse from string
    pub fn from_str(s: &str) -> Option<Self> {
        match s.to_lowercase().as_str() {
            "pdf" => Some(Self::Pdf),
            "svg" => Some(Self::Svg),
            "html" => Some(Self::Html),
            _ => None,
        }
    }

    /// Infer format from output path
    pub fn from_path(path: &Path) -> Option<Self> {
        path.extension()
            .and_then(|ext| ext.to_str())
            .and_then(Self::from_str)
    }

    /// Get Typst format argument
    pub fn typst_format(&self) -> &'static str {
        match self {
            Self::Pdf => "pdf",
            Self::Svg => "svg",
            Self::Html => "html",
        }
    }
}

/// Compilation options
#[derive(Debug, Clone)]
pub struct CompileOptions {
    /// Output file path
    pub output: PathBuf,
    /// Output format (inferred from output if not specified)
    pub format: Option<OutputFormat>,
    /// Brand data to inject (overrides content file brand)
    pub brand_data: Option<serde_json::Value>,
    /// Additional font paths from brand
    pub brand_font_paths: Vec<PathBuf>,
    /// Include position information
    pub with_positions: bool,
    /// Enable experimental HTML
    pub experimental_html: bool,
    /// Check-only mode (validate without generating output)
    pub check_only: bool,
}

/// Position of an editable element in the output
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ElementPosition {
    /// Element ID/path
    pub id: String,
    /// Kind (block or field)
    pub kind: String,
    /// Page number (1-based)
    pub page: u32,
    /// X coordinate (points)
    pub x: f64,
    /// Y coordinate (points)
    pub y: f64,
    /// Width (points)
    pub width: f64,
    /// Height (points)
    pub height: f64,
}

/// Compilation result
#[derive(Debug, Clone, Serialize)]
pub struct CompileResult {
    /// Status
    pub status: String,
    /// Output format
    pub format: String,
    /// Output file (for PDF)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub output: Option<PathBuf>,
    /// Pages (for SVG)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub pages: Option<Vec<PageInfo>>,
    /// Element positions (if requested)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub positions: Option<Vec<ElementPosition>>,
}

/// Page information for SVG output
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PageInfo {
    pub page: u32,
    pub file: PathBuf,
}

/// Typst compiler interface
pub struct TypstCompiler {
    /// Path to typst binary
    binary: PathBuf,
    /// Additional font paths
    font_paths: Vec<PathBuf>,
    /// Package path for bundled tmpltr Typst library
    package_path: PathBuf,
}

impl TypstCompiler {
    /// Create a new compiler from configuration
    pub fn from_config(config: &AppConfig) -> Result<Self> {
        let binary = if config.typst.binary.is_empty() {
            which_typst()?
        } else {
            PathBuf::from(&config.typst.binary)
        };

        let font_paths: Vec<PathBuf> = config
            .typst
            .font_paths
            .iter()
            .filter_map(|p| crate::config::expand_str_path(p).ok())
            .filter(|p| p.exists())
            .collect();

        let package_path = prepare_tmpltr_package()?;

        Ok(Self {
            binary,
            font_paths,
            package_path,
        })
    }

    /// Compile content to output
    pub fn compile(
        &self,
        content: &ContentFile,
        options: &CompileOptions,
    ) -> Result<CompileResult> {
        // For check-only mode, use a temp file
        let (output_path, temp_file) = if options.check_only {
            let temp = tempfile::NamedTempFile::new().map_err(|e| {
                Error::Io(std::io::Error::new(
                    std::io::ErrorKind::Other,
                    format!("creating temp file: {}", e),
                ))
            })?;
            let path = temp.path().to_path_buf();
            (path, Some(temp))
        } else {
            (options.output.clone(), None)
        };

        let format = options
            .format
            .or_else(|| OutputFormat::from_path(&output_path))
            .unwrap_or_default();

        // Check for experimental HTML
        if format == OutputFormat::Html && !options.experimental_html && !options.check_only {
            return Err(Error::Config(
                "HTML output requires --experimental-html flag".to_string(),
            ));
        }

        // Prepare data for Typst
        let data = self.prepare_data(content, options.brand_data.as_ref())?;
        let data_json = serde_json::to_string(&data)?;

        // Build command
        let mut cmd = Command::new(&self.binary);
        cmd.arg("compile");

        // Format
        cmd.arg("--format");
        cmd.arg(format.typst_format());

        // Pass data as input
        cmd.arg("--input");
        cmd.arg(format!("data={}", data_json));

        // Font paths from config
        for font_path in &self.font_paths {
            cmd.arg("--font-path");
            cmd.arg(font_path);
        }

        // Font paths from brand
        for font_path in &options.brand_font_paths {
            cmd.arg("--font-path");
            cmd.arg(font_path);
        }

        // Package path for bundled tmpltr Typst library
        cmd.arg("--package-path");
        cmd.arg(&self.package_path);

        // Set root to filesystem root so absolute paths in brand data work
        cmd.arg("--root");
        cmd.arg("/");

        // Input template (use resolved path if available, otherwise original)
        let template_path = content
            .meta
            .resolved_template
            .as_ref()
            .map(|p| p.as_path())
            .unwrap_or(Path::new(&content.meta.template));
        cmd.arg(template_path);

        // Output (Typst expects positional output argument)
        cmd.arg(&output_path);

        // Preserve existing package path env if set
        let package_paths = if let Ok(existing) = env::var("TYPST_PACKAGE_PATH") {
            let mut paths = env::split_paths(&existing).collect::<Vec<_>>();
            paths.insert(0, self.package_path.clone());
            env::join_paths(paths).ok()
        } else {
            env::join_paths([self.package_path.clone()]).ok()
        };
        if let Some(paths) = package_paths {
            cmd.env("TYPST_PACKAGE_PATH", paths);
        }

        // Execute
        let output = cmd.output().map_err(|e| Error::TypstCompilation {
            message: format!("failed to execute typst: {}", e),
            details: None,
        })?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            let warnings_only = stderr.lines().all(|line| {
                let lt = line.trim().to_lowercase();
                lt.is_empty() || lt.starts_with("warning")
            });

            if warnings_only {
                if !stderr.trim().is_empty() {
                    eprintln!("{}", stderr);
                }
            } else {
                let has_error = stderr
                    .lines()
                    .any(|line| line.to_lowercase().contains("error"));

                if has_error {
                    // Check for common error patterns and provide helpful guidance
                    let enhanced_message = enhance_error_message(&stderr);

                    let summary = stderr
                        .lines()
                        .find(|line| !line.trim().is_empty())
                        .unwrap_or("Typst compilation failed");
                    return Err(Error::TypstCompilation {
                        message: format!("Typst compilation failed: {}", summary),
                        details: Some(enhanced_message),
                    });
                } else if !stderr.trim().is_empty() {
                    eprintln!("{}", stderr);
                }
            }
        }

        // Drop temp file if in check mode (cleans up temp file)
        drop(temp_file);

        // Build result
        let result = if options.check_only {
            CompileResult {
                status: "ok".to_string(),
                format: "check".to_string(),
                output: None,
                pages: None,
                positions: None,
            }
        } else {
            match format {
                OutputFormat::Pdf | OutputFormat::Html => CompileResult {
                    status: "ok".to_string(),
                    format: format.typst_format().to_string(),
                    output: Some(options.output.clone()),
                    pages: None,
                    positions: if options.with_positions {
                        Some(Vec::new()) // TODO: Extract positions
                    } else {
                        None
                    },
                },
                OutputFormat::Svg => {
                    let pages = self.collect_svg_pages(&options.output)?;
                    CompileResult {
                        status: "ok".to_string(),
                        format: format.typst_format().to_string(),
                        output: None,
                        pages: Some(pages),
                        positions: if options.with_positions {
                            Some(Vec::new()) // TODO: Extract positions
                        } else {
                            None
                        },
                    }
                }
            }
        };

        Ok(result)
    }

    /// Prepare data structure for Typst
    fn prepare_data(
        &self,
        content: &ContentFile,
        brand_data: Option<&serde_json::Value>,
    ) -> Result<serde_json::Value> {
        // Convert TOML to JSON, processing markdown blocks
        let mut data = toml_to_json(content.as_toml())?;

        // Merge brand data if provided
        if let Some(brand) = brand_data {
            if let (Some(data_obj), Some(brand_obj)) = (data.as_object_mut(), brand.as_object()) {
                // Merge brand data under "brand" key
                data_obj.insert(
                    "brand".to_string(),
                    serde_json::Value::Object(brand_obj.clone()),
                );
            }
        }

        // Process markdown blocks
        if let Some(blocks) = data.get_mut("blocks").and_then(|v| v.as_object_mut()) {
            for (_name, block) in blocks.iter_mut() {
                if let Some(block_obj) = block.as_object_mut() {
                    let format = block_obj
                        .get("format")
                        .and_then(|v| v.as_str())
                        .unwrap_or("markdown");

                    if format == "markdown" {
                        if let Some(content) = block_obj.get("content").and_then(|v| v.as_str()) {
                            let typst_content = markdown_to_typst(content)?;
                            block_obj.insert(
                                "content".to_string(),
                                serde_json::Value::String(typst_content),
                            );
                        }
                    }
                }
            }
        }

        Ok(data)
    }

    /// Collect SVG page files
    fn collect_svg_pages(&self, output_pattern: &Path) -> Result<Vec<PageInfo>> {
        let mut pages = Vec::new();

        // SVG output uses patterns like output-{p}.svg
        let pattern = output_pattern.to_string_lossy();
        if pattern.contains("{p}") || pattern.contains("{0p}") {
            let parent = output_pattern.parent().unwrap_or(Path::new("."));
            let stem = output_pattern
                .file_stem()
                .and_then(|s| s.to_str())
                .unwrap_or("output");

            // Look for numbered files
            if let Ok(entries) = std::fs::read_dir(parent) {
                for entry in entries.flatten() {
                    let path = entry.path();
                    if let Some(name) = path.file_name().and_then(|s| s.to_str()) {
                        if name.starts_with(stem) && name.ends_with(".svg") {
                            // Extract page number
                            if let Some(num) = extract_page_number(name, stem) {
                                pages.push(PageInfo {
                                    page: num,
                                    file: path,
                                });
                            }
                        }
                    }
                }
            }
        } else if output_pattern.exists() {
            // Single page
            pages.push(PageInfo {
                page: 1,
                file: output_pattern.to_path_buf(),
            });
        }

        pages.sort_by_key(|p| p.page);
        Ok(pages)
    }
}

/// Convert TOML value to JSON
fn toml_to_json(value: &toml::Value) -> Result<serde_json::Value> {
    let json = match value {
        toml::Value::String(s) => serde_json::Value::String(s.clone()),
        toml::Value::Integer(i) => serde_json::Value::Number((*i).into()),
        toml::Value::Float(f) => serde_json::Number::from_f64(*f)
            .map(serde_json::Value::Number)
            .unwrap_or(serde_json::Value::Null),
        toml::Value::Boolean(b) => serde_json::Value::Bool(*b),
        toml::Value::Datetime(dt) => serde_json::Value::String(dt.to_string()),
        toml::Value::Array(arr) => {
            let items: Result<Vec<_>> = arr.iter().map(toml_to_json).collect();
            serde_json::Value::Array(items?)
        }
        toml::Value::Table(table) => {
            let mut map = serde_json::Map::new();
            for (k, v) in table {
                map.insert(k.clone(), toml_to_json(v)?);
            }
            serde_json::Value::Object(map)
        }
    };
    Ok(json)
}

/// Find typst binary in PATH
fn which_typst() -> Result<PathBuf> {
    which::which("typst").map_err(|_| {
        Error::Config(
            "typst binary not found in PATH. Install typst or set paths.typst_binary in config"
                .to_string(),
        )
    })
}

fn prepare_tmpltr_package() -> Result<PathBuf> {
    let base = env::temp_dir().join("tmpltr-typst-packages");
    let pkg_root = base.join("local").join("tmpltr-lib").join("1.0.0");
    let package_file = pkg_root.join("typst.toml");
    let entrypoint = pkg_root.join("lib.typ");

    std::fs::create_dir_all(&pkg_root).map_err(|e| {
        Error::Config(format!(
            "creating Typst package directory {}: {}",
            pkg_root.display(),
            e
        ))
    })?;

    let manifest = r#"[package]
name = "tmpltr-lib"
version = "1.0.0"
entrypoint = "lib.typ"
license = "MIT"
description = "tmpltr helper library"
"#;

    std::fs::write(&package_file, manifest).map_err(|e| {
        Error::Config(format!(
            "writing Typst package manifest {}: {}",
            package_file.display(),
            e
        ))
    })?;

    std::fs::write(
        &entrypoint,
        include_str!("../typst_templates/tmpltr-lib.typ"),
    )
    .map_err(|e| {
        Error::Config(format!(
            "writing Typst helper library {}: {}",
            entrypoint.display(),
            e
        ))
    })?;

    Ok(base)
}

/// Extract page number from SVG filename
fn extract_page_number(filename: &str, stem: &str) -> Option<u32> {
    let suffix = filename.strip_prefix(stem)?;
    let suffix = suffix
        .strip_prefix('-')
        .or_else(|| suffix.strip_prefix('_'))?;
    let num_str = suffix.strip_suffix(".svg")?;
    num_str.parse().ok()
}

/// Enhance error messages with helpful guidance for common issues
fn enhance_error_message(stderr: &str) -> String {
    let stderr_lower = stderr.to_lowercase();
    let mut hints = Vec::new();

    // Check for "file name too long" - common when json() is used instead of json.decode()
    // This happens because json() expects a file path, but receives raw JSON data
    if stderr_lower.contains("file name too long")
        || stderr_lower.contains("no such file or directory")
    {
        // Check if the error might be related to json() function misuse
        if stderr_lower.contains("json") || stderr_lower.contains("sys.inputs") {
            hints.push(
                "HINT: If your template uses `json(sys.inputs.at(\"data\"))`, change it to:\n\
                 \n\
                 #let data = json.decode(sys.inputs.at(\"data\", default: \"{}\"))\n\
                 \n\
                 The `json()` function expects a file path, but tmpltr passes data as a string.\n\
                 Use `json.decode()` to parse the JSON string directly."
                    .to_string(),
            );
        } else {
            hints.push(
                "HINT: This error often occurs when using `json(path)` where `path` is not a file.\n\
                 If you're parsing data from sys.inputs, use `json.decode()` instead of `json()`."
                    .to_string(),
            );
        }
    }

    // Check for common Typst syntax errors
    if stderr_lower.contains("expected") && stderr_lower.contains("found") {
        hints.push(
            "HINT: This is a Typst syntax error. Check your template for typos or incorrect syntax."
                .to_string(),
        );
    }

    // Check for missing function errors
    if stderr_lower.contains("unknown variable") || stderr_lower.contains("cannot find") {
        if stderr_lower.contains("tmpltr-data")
            || stderr_lower.contains("editable")
            || stderr_lower.contains("tmpltr-lib")
        {
            hints.push(
                "HINT: Make sure your template imports the tmpltr library:\n\
                 \n\
                 #import \"@local/tmpltr-lib:1.0.0\": editable, editable-block, tmpltr-data, md, get"
                    .to_string(),
            );
        }
    }

    // Check for missing data field errors
    if stderr_lower.contains("missing key") || stderr_lower.contains("key not found") {
        hints.push(
            "HINT: A required field is missing from your content file.\n\
             Check that all fields referenced in the template exist in your .toml content file."
                .to_string(),
        );
    }

    // Build the enhanced message
    if hints.is_empty() {
        stderr.to_string()
    } else {
        format!("{}\n\n{}", stderr, hints.join("\n\n"))
    }
}

/// Compilation error details
#[derive(Debug, Clone, Serialize)]
pub struct CompileError {
    pub status: String,
    pub kind: String,
    pub message: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub details: Option<String>,
}

impl From<Error> for CompileError {
    fn from(err: Error) -> Self {
        Self {
            status: "error".to_string(),
            kind: err.kind().to_string(),
            message: err.to_string(),
            details: if let Error::TypstCompilation { details, .. } = &err {
                details.clone()
            } else {
                None
            },
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_format_from_path() {
        assert_eq!(
            OutputFormat::from_path(Path::new("output.pdf")),
            Some(OutputFormat::Pdf)
        );
        assert_eq!(
            OutputFormat::from_path(Path::new("output.svg")),
            Some(OutputFormat::Svg)
        );
        assert_eq!(
            OutputFormat::from_path(Path::new("output.html")),
            Some(OutputFormat::Html)
        );
        assert_eq!(OutputFormat::from_path(Path::new("output.txt")), None);
    }

    #[test]
    fn test_extract_page_number() {
        assert_eq!(extract_page_number("output-1.svg", "output"), Some(1));
        assert_eq!(extract_page_number("output-01.svg", "output"), Some(1));
        assert_eq!(extract_page_number("output_2.svg", "output"), Some(2));
    }
}
