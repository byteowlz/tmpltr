//! Configuration management for tmpltr
//!
//! Handles XDG-compliant config paths, auto-creation, and environment variable expansion.

use std::env;
use std::fs;
use std::path::{Path, PathBuf};

use serde::{Deserialize, Serialize};

use crate::error::{Error, Result};

const APP_NAME: &str = "tmpltr";

/// Main configuration structure
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(default)]
pub struct AppConfig {
    /// Path configuration
    pub paths: PathsConfig,
    /// Brand configuration
    pub brand: BrandConfig,
    /// Typst configuration
    pub typst: TypstConfig,
    /// Output configuration
    pub output: OutputConfig,
    /// Experimental features
    pub experimental: ExperimentalConfig,
}

impl Default for AppConfig {
    fn default() -> Self {
        Self {
            paths: PathsConfig::default(),
            brand: BrandConfig::default(),
            typst: TypstConfig::default(),
            output: OutputConfig::default(),
            experimental: ExperimentalConfig::default(),
        }
    }
}

/// Path configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(default)]
pub struct PathsConfig {
    /// Directory containing templates (shared/general)
    pub templates_dir: Option<String>,
    /// Directory containing JSON schemas
    pub schemas_dir: Option<String>,
    /// Directory containing brand configurations (logos, fonts, colors)
    pub brands_dir: Option<String>,
    /// Cache directory
    pub cache_dir: Option<String>,
}

/// Brand configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(default)]
pub struct BrandConfig {
    /// Default brand ID to use when --brand is not specified
    pub default: Option<String>,
}

impl Default for PathsConfig {
    fn default() -> Self {
        Self {
            templates_dir: Some("$XDG_DATA_HOME/tmpltr/templates".to_string()),
            schemas_dir: Some("$XDG_DATA_HOME/tmpltr/schemas".to_string()),
            brands_dir: Some("$XDG_DATA_HOME/tmpltr/brands".to_string()),
            cache_dir: Some("$XDG_CACHE_HOME/tmpltr".to_string()),
        }
    }
}

impl Default for BrandConfig {
    fn default() -> Self {
        Self { default: None }
    }
}

/// Typst-related configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(default)]
pub struct TypstConfig {
    /// Path to typst binary (empty = use PATH)
    pub binary: String,
    /// Additional font paths
    pub font_paths: Vec<String>,
}

impl Default for TypstConfig {
    fn default() -> Self {
        let mut font_paths = Vec::new();

        // Add platform-specific default font directories
        #[cfg(target_os = "macos")]
        {
            font_paths.push("~/Library/Fonts".to_string());
            font_paths.push("/Library/Fonts".to_string());
        }

        #[cfg(target_os = "linux")]
        {
            font_paths.push("~/.local/share/fonts".to_string());
            font_paths.push("~/.fonts".to_string());
            font_paths.push("/usr/share/fonts".to_string());
        }

        #[cfg(target_os = "windows")]
        {
            font_paths.push("C:/Windows/Fonts".to_string());
        }

        Self {
            binary: String::new(),
            font_paths,
        }
    }
}

/// Output configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(default)]
pub struct OutputConfig {
    /// Default output format (pdf, svg, html)
    pub format: String,
    /// Watch debounce in milliseconds
    pub watch_debounce_ms: u64,
}

impl Default for OutputConfig {
    fn default() -> Self {
        Self {
            format: "pdf".to_string(),
            watch_debounce_ms: 300,
        }
    }
}

/// Experimental features configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(default)]
pub struct ExperimentalConfig {
    /// Enable experimental HTML output
    pub html: bool,
}

impl Default for ExperimentalConfig {
    fn default() -> Self {
        Self { html: false }
    }
}

/// Resolved application paths
#[derive(Debug, Clone)]
pub struct ResolvedPaths {
    /// Config file path
    pub config_file: PathBuf,
    /// Templates directory (shared/general)
    pub templates_dir: PathBuf,
    /// Schemas directory
    pub schemas_dir: PathBuf,
    /// Brands directory (brand-specific logos, fonts, colors)
    pub brands_dir: PathBuf,
    /// Cache directory
    pub cache_dir: PathBuf,
    /// Data directory
    pub data_dir: PathBuf,
}

impl ResolvedPaths {
    /// Discover and resolve all paths
    pub fn discover(config_override: Option<PathBuf>) -> Result<Self> {
        let config_file = match config_override {
            Some(path) => {
                let expanded = expand_path(&path)?;
                if expanded.is_dir() {
                    expanded.join("config.toml")
                } else {
                    expanded
                }
            }
            None => default_config_dir()?.join("config.toml"),
        };

        let data_dir = default_data_dir()?;
        let cache_dir = default_cache_dir()?;

        Ok(Self {
            config_file,
            templates_dir: data_dir.join("templates"),
            schemas_dir: data_dir.join("schemas"),
            brands_dir: data_dir.join("brands"),
            cache_dir,
            data_dir,
        })
    }

    /// Apply overrides from configuration
    pub fn apply_config(&mut self, config: &AppConfig) -> Result<()> {
        if let Some(ref dir) = config.paths.templates_dir {
            self.templates_dir = expand_str_path(dir)?;
        }
        if let Some(ref dir) = config.paths.schemas_dir {
            self.schemas_dir = expand_str_path(dir)?;
        }
        if let Some(ref dir) = config.paths.brands_dir {
            self.brands_dir = expand_str_path(dir)?;
        }
        if let Some(ref dir) = config.paths.cache_dir {
            self.cache_dir = expand_str_path(dir)?;
        }
        Ok(())
    }

    /// Ensure all directories exist
    pub fn ensure_directories(&self) -> Result<()> {
        fs::create_dir_all(&self.templates_dir).map_err(|e| {
            Error::Io(std::io::Error::new(
                e.kind(),
                format!(
                    "creating templates directory {}: {}",
                    self.templates_dir.display(),
                    e
                ),
            ))
        })?;
        fs::create_dir_all(&self.schemas_dir).map_err(|e| {
            Error::Io(std::io::Error::new(
                e.kind(),
                format!(
                    "creating schemas directory {}: {}",
                    self.schemas_dir.display(),
                    e
                ),
            ))
        })?;
        fs::create_dir_all(&self.brands_dir).map_err(|e| {
            Error::Io(std::io::Error::new(
                e.kind(),
                format!(
                    "creating brands directory {}: {}",
                    self.brands_dir.display(),
                    e
                ),
            ))
        })?;
        fs::create_dir_all(&self.cache_dir).map_err(|e| {
            Error::Io(std::io::Error::new(
                e.kind(),
                format!(
                    "creating cache directory {}: {}",
                    self.cache_dir.display(),
                    e
                ),
            ))
        })?;
        Ok(())
    }
}

/// Load configuration, creating default if it doesn't exist
pub fn load_or_create_config(paths: &ResolvedPaths) -> Result<AppConfig> {
    if !paths.config_file.exists() {
        write_default_config(&paths.config_file)?;
    }

    let content = fs::read_to_string(&paths.config_file).map_err(|e| {
        Error::Io(std::io::Error::new(
            e.kind(),
            format!("reading config file {}: {}", paths.config_file.display(), e),
        ))
    })?;

    let config: AppConfig = toml::from_str(&content)?;
    Ok(config)
}

/// Write the default configuration file
pub fn write_default_config(path: &Path) -> Result<()> {
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent).map_err(|e| {
            Error::Io(std::io::Error::new(
                e.kind(),
                format!("creating config directory {}: {}", parent.display(), e),
            ))
        })?;
    }

    let config = AppConfig::default();
    let toml_content = toml::to_string_pretty(&config)?;

    let content = format!(
        r#"# tmpltr configuration
# Generated automatically on first run
# $schema = "https://tmpltr.dev/schemas/config.schema.json"

{}"#,
        toml_content
    );

    fs::write(path, content).map_err(|e| {
        Error::Io(std::io::Error::new(
            e.kind(),
            format!("writing config file {}: {}", path.display(), e),
        ))
    })?;

    log::info!("Created default config at {}", path.display());
    Ok(())
}

/// Expand a PathBuf, handling ~ and environment variables
pub fn expand_path(path: &Path) -> Result<PathBuf> {
    if let Some(text) = path.to_str() {
        expand_str_path(text)
    } else {
        Ok(path.to_path_buf())
    }
}

/// Expand a string path, handling ~ and environment variables
pub fn expand_str_path(text: &str) -> Result<PathBuf> {
    let expanded = shellexpand::full(text)
        .map_err(|e| Error::Config(format!("expanding path '{}': {}", text, e)))?;
    // Normalize the path to remove double slashes from env vars with trailing slashes
    let path = PathBuf::from(expanded.to_string());
    let normalized: PathBuf = path.components().collect();
    Ok(normalized)
}

/// Resolve a base directory using "option B" rules:
/// an explicit absolute `XDG_*` value wins on ANY OS; otherwise on unix
/// (including macOS) join the unix-relative path under `$HOME` (NOT
/// `~/Library`); otherwise on Windows use the provided `%APPDATA%` /
/// `%LOCALAPPDATA%` directory.
fn resolve_base(
    xdg: Option<PathBuf>,
    home: Option<PathBuf>,
    win_dir: Option<PathBuf>,
    is_windows: bool,
    unix_rel: &str,
) -> Option<PathBuf> {
    if let Some(p) = xdg.filter(|p| p.is_absolute()) {
        return Some(p);
    }
    if is_windows {
        win_dir
    } else {
        home.map(|h| h.join(unix_rel))
    }
}

/// Compute the base directory for the current platform from environment
/// variables, then leave the caller to join the application name.
fn base_dir(xdg_var: &str, unix_rel: &str, win_var: &str) -> Result<PathBuf> {
    resolve_base(
        env::var_os(xdg_var).map(PathBuf::from),
        env::var_os("HOME").map(PathBuf::from),
        env::var_os(win_var).map(PathBuf::from),
        cfg!(windows),
        unix_rel,
    )
    .ok_or_else(|| Error::Config(format!("unable to determine base directory ({xdg_var})")))
}

/// Get the default config directory (XDG compliant)
pub fn default_config_dir() -> Result<PathBuf> {
    Ok(base_dir("XDG_CONFIG_HOME", ".config", "APPDATA")?.join(APP_NAME))
}

/// Get the default data directory (XDG compliant)
pub fn default_data_dir() -> Result<PathBuf> {
    Ok(base_dir("XDG_DATA_HOME", ".local/share", "APPDATA")?.join(APP_NAME))
}

/// Get the default state directory (XDG compliant)
pub fn default_state_dir() -> Result<PathBuf> {
    Ok(base_dir("XDG_STATE_HOME", ".local/state", "LOCALAPPDATA")?.join(APP_NAME))
}

/// Get the default cache directory (XDG compliant)
pub fn default_cache_dir() -> Result<PathBuf> {
    Ok(base_dir("XDG_CACHE_HOME", ".cache", "LOCALAPPDATA")?.join(APP_NAME))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_default_config() {
        let config = AppConfig::default();
        assert_eq!(config.output.format, "pdf");
        assert_eq!(config.output.watch_debounce_ms, 300);
        assert!(!config.experimental.html);
    }

    #[test]
    fn test_expand_home() {
        let path = expand_str_path("~/test").unwrap();
        assert!(!path.to_string_lossy().contains('~'));
    }

    #[test]
    fn resolve_base_absolute_xdg_wins_on_unix() {
        let got = resolve_base(
            Some(PathBuf::from("/xdg/config")),
            Some(PathBuf::from("/home/user")),
            None,
            false,
            ".config",
        );
        assert_eq!(got, Some(PathBuf::from("/xdg/config")));
    }

    #[test]
    fn resolve_base_absolute_xdg_wins_on_windows() {
        let got = resolve_base(
            Some(PathBuf::from("/xdg/config")),
            None,
            Some(PathBuf::from("C:/Users/u/AppData/Roaming")),
            true,
            ".config",
        );
        assert_eq!(got, Some(PathBuf::from("/xdg/config")));
    }

    #[test]
    fn resolve_base_relative_xdg_ignored_falls_back_to_home() {
        let got = resolve_base(
            Some(PathBuf::from("relative/path")),
            Some(PathBuf::from("/home/user")),
            None,
            false,
            ".config",
        );
        assert_eq!(got, Some(PathBuf::from("/home/user/.config")));
    }

    #[test]
    fn resolve_base_unix_uses_home_join_not_library() {
        let got = resolve_base(
            None,
            Some(PathBuf::from("/Users/u")),
            None,
            false,
            ".local/share",
        );
        assert_eq!(got, Some(PathBuf::from("/Users/u/.local/share")));
    }

    #[test]
    fn resolve_base_windows_uses_win_dir() {
        let got = resolve_base(
            None,
            Some(PathBuf::from("/home/user")),
            Some(PathBuf::from("C:/Users/u/AppData/Local")),
            true,
            ".cache",
        );
        assert_eq!(got, Some(PathBuf::from("C:/Users/u/AppData/Local")));
    }

    #[test]
    fn resolve_base_none_when_no_sources() {
        assert_eq!(resolve_base(None, None, None, false, ".config"), None);
        assert_eq!(resolve_base(None, None, None, true, ".cache"), None);
    }
}
