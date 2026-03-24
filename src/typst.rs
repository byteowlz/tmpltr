//! Typst compilation interface
//!
//! Handles invoking the Typst compiler with proper arguments and error handling.

use std::env;
use std::fs;
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
    /// Self-contained .typ file with data inlined and library embedded
    Typ,
}

impl OutputFormat {
    /// Parse from string
    pub fn from_str(s: &str) -> Option<Self> {
        match s.to_lowercase().as_str() {
            "pdf" => Some(Self::Pdf),
            "svg" => Some(Self::Svg),
            "html" => Some(Self::Html),
            "typ" | "typst" => Some(Self::Typ),
            _ => None,
        }
    }

    /// Infer format from output path
    pub fn from_path(path: &Path) -> Option<Self> {
        path.extension()
            .and_then(|ext| ext.to_str())
            .and_then(Self::from_str)
    }

    /// Get Typst format argument (only for formats that typst compile supports)
    pub fn typst_format(&self) -> &'static str {
        match self {
            Self::Pdf => "pdf",
            Self::Svg => "svg",
            Self::Html => "html",
            Self::Typ => "pdf", // not used directly, but avoids panic
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

    /// Export a self-contained .typ file with data and library inlined.
    /// The resulting file can be opened directly in the Typst online editor.
    pub fn export_typ(
        &self,
        content: &ContentFile,
        options: &CompileOptions,
    ) -> Result<CompileResult> {
        let data = self.prepare_data(content, options.brand_data.as_ref())?;
        let data_json = serde_json::to_string_pretty(&data)?;

        // Read the template source
        let template_path = content
            .meta
            .resolved_template
            .as_ref()
            .map(|p| p.as_path())
            .unwrap_or(Path::new(&content.meta.template));

        let template_source = fs::read_to_string(template_path).map_err(|e: std::io::Error| {
            Error::Io(std::io::Error::new(
                e.kind(),
                format!("reading template {}: {}", template_path.display(), e),
            ))
        })?;

        // Read the tmpltr-lib source (entrypoint is lib.typ)
        let lib_path = self.package_path.join("local/tmpltr-lib/1.0.0/lib.typ");
        let lib_source = fs::read_to_string(&lib_path).map_err(|e: std::io::Error| {
            Error::Io(std::io::Error::new(
                e.kind(),
                format!("reading tmpltr-lib {}: {}", lib_path.display(), e),
            ))
        })?;

        // Collect and inline image assets referenced in the data
        let image_paths = collect_image_paths(&data);
        let mut inlined_images: Vec<(String, String, String)> = Vec::new(); // (original_path, var_name, content)

        for (i, path_str) in image_paths.iter().enumerate() {
            let img_path = Path::new(path_str);
            if img_path.exists() {
                let var_name = format!("_tmpltr_asset_{}", i);
                match fs::read_to_string(img_path) {
                    Ok(content) => {
                        inlined_images.push((path_str.clone(), var_name, content));
                    }
                    Err(e) => {
                        log::warn!("Could not inline image {}: {}", path_str, e);
                    }
                }
            }
        }

        // Replace image paths in data JSON with placeholder markers
        let mut data_json_patched = data_json.clone();
        for (original_path, var_name, _) in &inlined_images {
            data_json_patched =
                data_json_patched.replace(original_path, &format!("__INLINE:{}__", var_name));
        }

        // Build the self-contained .typ file
        let mut output = String::new();

        // Header comment
        output.push_str("// Self-contained Typst file exported by tmpltr\n");
        output.push_str("// This file can be used directly in the Typst online editor.\n");
        output.push_str("// All assets (images, data, library) are embedded inline.\n");
        output.push_str("\n");

        // Inline image assets as raw string variables
        if !inlined_images.is_empty() {
            output.push_str("// ── Inlined image assets ──\n");
            for (original_path, var_name, content) in &inlined_images {
                output.push_str(&format!("// Source: {}\n", original_path));
                // Use raw block syntax to avoid escaping issues
                output.push_str(&format!(
                    "#let {} = bytes(\"{}\")\n\n",
                    var_name,
                    content
                        .replace('\\', "\\\\")
                        .replace('"', "\\\"")
                        .replace('\n', "\\n")
                ));
            }
            output.push('\n');
        }

        // Inline the data as a JSON string parsed at the top
        output.push_str("// ── Inlined data ──\n");
        output.push_str("#let _tmpltr_inline_data = json(bytes(\"");
        // Escape the JSON for embedding in a Typst string
        let escaped_json = data_json_patched
            .replace('\\', "\\\\")
            .replace('"', "\\\"")
            .replace('\n', "\\n");
        output.push_str(&escaped_json);
        output.push_str("\"))\n\n");

        // If we have inlined images, patch the data dict to replace marker strings with bytes
        if !inlined_images.is_empty() {
            output.push_str("// ── Patch inlined assets into data ──\n");
            output.push_str("#let _patch-assets(data) = {\n");
            output.push_str("  let d = data\n");
            // Patch logo paths
            output.push_str("  if \"brand\" in d and \"logos\" in d.brand {\n");
            output.push_str("    let logos = d.brand.logos\n");
            for (_, var_name, _) in &inlined_images {
                let marker = format!("__INLINE:{}__", var_name);
                output.push_str(&format!(
                    "    for (key, val) in logos {{ if val == \"{}\" {{ logos.insert(key, \"{}\") }} }}\n",
                    marker, marker
                ));
            }
            output.push_str("    d.brand.logos = logos\n");
            output.push_str("  }\n");
            // Patch top-level logo field
            output.push_str("  if \"brand\" in d and \"logo\" in d.brand {\n");
            for (_, var_name, _) in &inlined_images {
                let marker = format!("__INLINE:{}__", var_name);
                output.push_str(&format!(
                    "    if d.brand.logo == \"{}\" {{ d.brand.logo = \"{}\" }}\n",
                    marker, marker
                ));
            }
            output.push_str("  }\n");
            output.push_str("  d\n");
            output.push_str("}\n");
            output.push_str("#let _tmpltr_inline_data = _patch-assets(_tmpltr_inline_data)\n\n");

            // Override image() to intercept inlined asset markers
            output.push_str("// ── Image wrapper for inlined assets ──\n");
            output.push_str("#let _original_image = image\n");
            output.push_str("#let image(source, ..args) = {\n");
            for (_, var_name, _) in &inlined_images {
                let marker = format!("__INLINE:{}__", var_name);
                output.push_str(&format!(
                    "  if type(source) == str and source == \"{}\" {{ return _original_image({}, ..args) }}\n",
                    marker, var_name
                ));
            }
            output.push_str("  _original_image(source, ..args)\n");
            output.push_str("}\n\n");
        }

        // Inline the library, replacing tmpltr-data() to return inlined data
        output.push_str("// ── Inlined tmpltr-lib ──\n");
        let modified_lib = lib_source.replace(
            "let raw = sys.inputs.at(\"data\", default: \"{}\")\n  // Modern Typst: pass bytes directly to json() instead of using json.decode()\n  json(bytes(raw))",
            "_tmpltr_inline_data",
        );
        output.push_str(&modified_lib);
        output.push_str("\n\n");

        // Inline the template, removing the import line
        output.push_str("// ── Template ──\n");
        for line in template_source.lines() {
            let line_str: &str = line;
            if line_str.starts_with("#import \"@local/tmpltr-lib") {
                // Replace import with a comment — functions are already inlined above
                output.push_str("// (import replaced by inlined library above)\n");
            } else {
                output.push_str(line_str);
                output.push('\n');
            }
        }

        // Write the output
        let output_path = &options.output;
        fs::write(output_path, &output).map_err(|e: std::io::Error| {
            Error::Io(std::io::Error::new(
                e.kind(),
                format!("writing {}: {}", output_path.display(), e),
            ))
        })?;

        Ok(CompileResult {
            status: "exported".to_string(),
            format: "typ".to_string(),
            output: Some(output_path.clone()),
            pages: None,
            positions: None,
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

            // Check if there are any actual errors (not just warnings).
            // Typst formats diagnostics as multi-line blocks starting with "error:" or "warning:".
            // We look for the presence of "error:" at the start of a trimmed line to distinguish
            // real errors from warnings (which may also cause a non-zero exit code).
            let has_error = stderr.lines().any(|line| {
                let lt = line.trim().to_lowercase();
                lt.starts_with("error:")
                    || lt.starts_with("error[")
            });

            if has_error {
                let enhanced_message = enhance_error_message(&stderr);

                let summary = stderr
                    .lines()
                    .find(|line| {
                        let lt = line.trim().to_lowercase();
                        lt.starts_with("error:")
                    })
                    .unwrap_or("Typst compilation failed");
                return Err(Error::TypstCompilation {
                    message: format!("Typst compilation failed: {}", summary),
                    details: Some(enhanced_message),
                });
            } else if !stderr.trim().is_empty() {
                // Warnings only -- print them but don't fail
                eprintln!("{}", stderr);
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
                OutputFormat::Typ => {
                    // This branch should not be reached — Typ is handled
                    // by export_typ() before calling compile().
                    unreachable!("Typ format should be handled by export_typ()")
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

/// Collect all image/asset file paths from the data JSON (logo paths, etc.)
fn collect_image_paths(data: &serde_json::Value) -> Vec<String> {
    let mut paths = Vec::new();

    // Collect from brand.logos.*
    if let Some(logos) = data
        .get("brand")
        .and_then(|b| b.get("logos"))
        .and_then(|l| l.as_object())
    {
        for val in logos.values() {
            if let Some(s) = val.as_str() {
                if !s.is_empty() {
                    paths.push(s.to_string());
                }
            }
        }
    }

    // Collect from brand.logo (top-level shortcut)
    if let Some(logo) = data
        .get("brand")
        .and_then(|b| b.get("logo"))
        .and_then(|l| l.as_str())
    {
        if !logo.is_empty() && !paths.contains(&logo.to_string()) {
            paths.push(logo.to_string());
        }
    }

    paths
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
