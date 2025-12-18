//! Brand data model and parsing
//!
//! Provides structures for brand metadata (colors, logos, typography) and
//! helpers to parse `brand.toml` files with multilingual fields.

use std::collections::{BTreeMap, HashSet};
use std::fs;
use std::path::{Path, PathBuf};

use serde::{Deserialize, Serialize};

use crate::config::expand_str_path;
use crate::error::{Error, Result};

const BRAND_FILE_NAME: &str = "brand.toml";
const DEFAULT_LANGUAGE_KEY: &str = "default";

/// A localized string supporting multiple language codes.
#[derive(Debug, Clone, Serialize, Default, PartialEq, Eq)]
#[serde(transparent)]
pub struct LocalizedText(BTreeMap<String, String>);

impl LocalizedText {
    /// Resolve the best matching string for a language code with fallbacks.
    pub fn resolve(&self, lang: Option<&str>, default_lang: Option<&str>) -> Option<&str> {
        if self.0.is_empty() {
            return None;
        }

        if let Some(lang) = lang {
            if let Some(val) = self.0.get(lang) {
                return Some(val);
            }
        }

        if let Some(lang) = default_lang {
            if let Some(val) = self.0.get(lang) {
                return Some(val);
            }
        }

        if let Some(val) = self.0.get(DEFAULT_LANGUAGE_KEY) {
            return Some(val);
        }

        self.0.values().next().map(|s| s.as_str())
    }

    /// Language codes present in this text (excluding the default bucket).
    pub fn languages(&self) -> Vec<String> {
        self.0
            .keys()
            .filter(|k| k.as_str() != DEFAULT_LANGUAGE_KEY)
            .cloned()
            .collect()
    }

    /// Whether this localized text has any entries.
    pub fn is_empty(&self) -> bool {
        self.0.is_empty()
    }
}

impl<'de> Deserialize<'de> for LocalizedText {
    fn deserialize<D>(deserializer: D) -> std::result::Result<Self, D::Error>
    where
        D: serde::Deserializer<'de>,
    {
        #[derive(Deserialize)]
        #[serde(untagged)]
        enum Helper {
            Map(BTreeMap<String, String>),
            Text(String),
        }

        let helper = Helper::deserialize(deserializer)?;
        let map = match helper {
            Helper::Map(map) => map,
            Helper::Text(text) => {
                let mut map = BTreeMap::new();
                map.insert(DEFAULT_LANGUAGE_KEY.to_string(), text);
                map
            }
        };

        Ok(LocalizedText(map))
    }
}

/// Core brand definition with resolved asset paths.
#[derive(Debug, Clone)]
pub struct Brand {
    /// Brand identifier (directory or canonical name)
    pub id: String,
    /// Preferred default language code
    pub default_language: Option<String>,
    /// Languages advertised by this brand
    pub languages: Vec<String>,
    /// Localized name
    pub name: LocalizedText,
    /// Localized description
    pub description: Option<LocalizedText>,
    /// Color palette
    pub colors: BrandColors,
    /// Logo assets
    pub logos: BrandLogos,
    /// Typography settings
    pub typography: BrandTypography,
    /// Contact details
    pub contact: Option<BrandContact>,
    /// Additional top-level keys for extensibility
    pub extra: toml::value::Table,
    /// Source information
    pub source: BrandSource,
}

/// Metadata about where the brand was loaded from.
#[derive(Debug, Clone)]
pub struct BrandSource {
    /// Path to the brand.toml file
    pub file: PathBuf,
    /// Directory containing the brand assets
    pub root_dir: PathBuf,
}

/// Colors defined for the brand.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct BrandColors {
    pub primary: Option<String>,
    pub secondary: Option<String>,
    pub accent: Option<String>,
    pub background: Option<String>,
    pub text: Option<String>,
    #[serde(default)]
    pub palette: BTreeMap<String, String>,
}

/// Logo asset references.
#[derive(Debug, Clone, Default)]
pub struct BrandLogos {
    pub primary: Option<AssetPath>,
    pub secondary: Option<AssetPath>,
    pub monochrome: Option<AssetPath>,
    pub favicon: Option<AssetPath>,
}

/// Font references grouped by usage.
#[derive(Debug, Clone, Default)]
pub struct BrandTypography {
    pub body: Option<FontFace>,
    pub heading: Option<FontFace>,
    pub mono: Option<FontFace>,
    pub extra: BTreeMap<String, FontFace>,
}

/// A single font face definition.
#[derive(Debug, Clone)]
pub struct FontFace {
    pub family: String,
    pub files: Vec<PathBuf>,
    pub weight: Option<u16>,
    pub style: Option<String>,
}

/// Contact information for a brand.
#[derive(Debug, Clone, Default)]
pub struct BrandContact {
    pub company: Option<LocalizedText>,
    pub address: Option<LocalizedText>,
    pub phone: Option<String>,
    pub email: Option<String>,
    pub website: Option<String>,
    pub extra: toml::value::Table,
}

/// A resolved asset path.
#[derive(Debug, Clone)]
pub struct AssetPath {
    pub original: String,
    pub resolved: PathBuf,
}

/// Summary information about a brand (used for listings).
#[derive(Debug, Clone)]
pub struct BrandSummary {
    pub id: String,
    pub name: Option<String>,
    pub languages: Vec<String>,
    pub path: PathBuf,
}

/// Loads brand definitions from search paths.
pub struct BrandRegistry {
    search_paths: Vec<PathBuf>,
}

impl BrandRegistry {
    /// Create a new registry with search paths.
    pub fn new(search_paths: Vec<PathBuf>) -> Self {
        Self { search_paths }
    }

    /// Discover available brands.
    pub fn list(&self) -> Result<Vec<BrandSummary>> {
        let mut seen = HashSet::new();
        let mut summaries = Vec::new();

        for path in &self.search_paths {
            if !path.exists() {
                continue;
            }

            if path.is_file() && path.file_name() == Some(BRAND_FILE_NAME.as_ref()) {
                if let Ok(summary) = load_brand_summary(path) {
                    if seen.insert(summary.id.clone()) {
                        summaries.push(summary);
                    }
                }
                continue;
            }

            if let Ok(entries) = fs::read_dir(path) {
                for entry in entries.flatten() {
                    let entry_path = entry.path();
                    if entry_path.is_dir() {
                        let brand_file = entry_path.join(BRAND_FILE_NAME);
                        if brand_file.exists() {
                            if let Ok(summary) = load_brand_summary(&brand_file) {
                                if seen.insert(summary.id.clone()) {
                                    summaries.push(summary);
                                }
                            }
                        }
                    } else if entry_path
                        .file_name()
                        .map(|n| n == BRAND_FILE_NAME)
                        .unwrap_or(false)
                    {
                        if let Ok(summary) = load_brand_summary(&entry_path) {
                            if seen.insert(summary.id.clone()) {
                                summaries.push(summary);
                            }
                        }
                    }
                }
            }
        }

        summaries.sort_by(|a, b| a.id.cmp(&b.id));
        Ok(summaries)
    }

    /// Load a brand by id or explicit path.
    pub fn load(&self, id_or_path: &str) -> Result<Brand> {
        let direct_path = PathBuf::from(id_or_path);
        if direct_path.exists() {
            let path = if direct_path.is_dir() {
                direct_path.join(BRAND_FILE_NAME)
            } else {
                direct_path
            };
            return Brand::from_file(path);
        }

        for path in &self.search_paths {
            let candidate = path.join(id_or_path).join(BRAND_FILE_NAME);
            if candidate.exists() {
                return Brand::from_file(candidate);
            }
            let alt = path.join(format!("{}.toml", id_or_path));
            if alt.exists() {
                return Brand::from_file(alt);
            }
        }

        Err(Error::Brand(format!("brand '{}' not found", id_or_path)))
    }
}

impl Brand {
    /// Load a brand from a `brand.toml` file.
    pub fn from_file(path: impl AsRef<Path>) -> Result<Self> {
        let path = path.as_ref();
        let content = fs::read_to_string(path).map_err(|e| {
            if e.kind() == std::io::ErrorKind::NotFound {
                Error::FileNotFound {
                    path: path.to_path_buf(),
                }
            } else {
                Error::Brand(format!("reading brand file {}: {}", path.display(), e))
            }
        })?;

        let base_dir = path
            .parent()
            .map(|p| p.to_path_buf())
            .unwrap_or_else(|| PathBuf::from("."));

        Self::from_str(
            &content,
            BrandSource {
                file: path.to_path_buf(),
                root_dir: base_dir,
            },
        )
    }

    /// Parse a brand from raw TOML content.
    pub fn from_str(content: &str, source: BrandSource) -> Result<Self> {
        let config: BrandConfig = toml::from_str(content)?;
        Brand::from_config(config, source)
    }

    fn from_config(config: BrandConfig, source: BrandSource) -> Result<Self> {
        if config.id.trim().is_empty() {
            return Err(Error::Brand("brand id is required".to_string()));
        }

        if config.name.is_empty() {
            return Err(Error::Brand("brand name is required".to_string()));
        }

        let mut languages = dedupe_languages(config.languages);
        for lang in config.name.languages() {
            if !languages.contains(&lang) {
                languages.push(lang);
            }
        }

        if let Some(ref description) = config.description {
            for lang in description.languages() {
                if !languages.contains(&lang) {
                    languages.push(lang);
                }
            }
        }

        if let Some(ref contact) = config.contact {
            if let Some(company) = &contact.company {
                for lang in company.languages() {
                    if !languages.contains(&lang) {
                        languages.push(lang);
                    }
                }
            }
            if let Some(address) = &contact.address {
                for lang in address.languages() {
                    if !languages.contains(&lang) {
                        languages.push(lang);
                    }
                }
            }
        }

        if languages.is_empty() {
            if let Some(default_lang) = &config.default_language {
                languages.push(default_lang.clone());
            } else if let Some(first_lang) = config.name.languages().first().cloned() {
                languages.push(first_lang);
            } else {
                languages.push("en".to_string());
            }
        } else if let Some(default_lang) = &config.default_language {
            if !languages.contains(default_lang) {
                languages.push(default_lang.clone());
            }
        }

        let default_language = config
            .default_language
            .or_else(|| languages.first().cloned());

        let logos = BrandLogos::from_config(config.logos, &source.root_dir)?;
        let typography = BrandTypography::from_config(config.typography, &source.root_dir)?;

        Ok(Brand {
            id: config.id,
            default_language,
            languages,
            name: config.name,
            description: config.description,
            colors: config.colors,
            logos,
            typography,
            contact: config.contact.map(|c| c.into_contact()),
            extra: config.extra,
            source,
        })
    }

    /// Resolve the brand name for a language code.
    pub fn name_for(&self, lang: Option<&str>) -> Option<&str> {
        self.name.resolve(lang, self.default_language.as_deref())
    }

    /// Resolve the brand description for a language code.
    pub fn description_for(&self, lang: Option<&str>) -> Option<&str> {
        self.description
            .as_ref()
            .and_then(|desc| desc.resolve(lang, self.default_language.as_deref()))
    }
}

/// Internal representation of a brand TOML file.
#[derive(Debug, Clone, Deserialize)]
struct BrandConfig {
    pub id: String,
    #[serde(default)]
    pub default_language: Option<String>,
    #[serde(default)]
    pub languages: Vec<String>,
    pub name: LocalizedText,
    #[serde(default)]
    pub description: Option<LocalizedText>,
    #[serde(default)]
    pub colors: BrandColors,
    #[serde(default)]
    pub logos: BrandLogosConfig,
    #[serde(default)]
    pub typography: BrandTypographyConfig,
    #[serde(default)]
    pub contact: Option<BrandContactConfig>,
    #[serde(default)]
    pub extra: toml::value::Table,
}

#[derive(Debug, Clone, Default, Deserialize)]
struct BrandLogosConfig {
    pub primary: Option<String>,
    pub secondary: Option<String>,
    pub monochrome: Option<String>,
    pub favicon: Option<String>,
}

impl BrandLogos {
    fn from_config(config: BrandLogosConfig, base_dir: &Path) -> Result<Self> {
        Ok(Self {
            primary: config
                .primary
                .map(|p| AssetPath::new(p, base_dir))
                .transpose()?,
            secondary: config
                .secondary
                .map(|p| AssetPath::new(p, base_dir))
                .transpose()?,
            monochrome: config
                .monochrome
                .map(|p| AssetPath::new(p, base_dir))
                .transpose()?,
            favicon: config
                .favicon
                .map(|p| AssetPath::new(p, base_dir))
                .transpose()?,
        })
    }
}

impl AssetPath {
    fn new(path: String, base_dir: &Path) -> Result<Self> {
        let resolved = resolve_path(base_dir, &path)?;
        Ok(Self {
            original: path,
            resolved,
        })
    }
}

#[derive(Debug, Clone, Default, Deserialize)]
struct BrandTypographyConfig {
    pub body: Option<FontFaceConfig>,
    pub heading: Option<FontFaceConfig>,
    pub mono: Option<FontFaceConfig>,
    #[serde(default)]
    pub extra: BTreeMap<String, FontFaceConfig>,
}

#[derive(Debug, Clone, Default, Deserialize)]
struct FontFaceConfig {
    pub family: Option<String>,
    #[serde(default)]
    pub files: Vec<String>,
    #[serde(default)]
    pub weight: Option<u16>,
    #[serde(default)]
    pub style: Option<String>,
}

impl BrandTypography {
    fn from_config(config: BrandTypographyConfig, base_dir: &Path) -> Result<Self> {
        let body = FontFace::from_config(config.body, base_dir)?;
        let heading = FontFace::from_config(config.heading, base_dir)?;
        let mono = FontFace::from_config(config.mono, base_dir)?;

        let mut extra = BTreeMap::new();
        for (key, cfg) in config.extra {
            if let Some(face) = FontFace::from_config(Some(cfg), base_dir)? {
                extra.insert(key, face);
            }
        }

        Ok(Self {
            body,
            heading,
            mono,
            extra,
        })
    }
}

impl FontFace {
    fn from_config(config: Option<FontFaceConfig>, base_dir: &Path) -> Result<Option<Self>> {
        let config = match config {
            Some(cfg) => cfg,
            None => return Ok(None),
        };

        let family = match config.family {
            Some(fam) if !fam.trim().is_empty() => fam,
            _ => {
                return Err(Error::Brand(
                    "font face requires a non-empty family name".to_string(),
                ))
            }
        };

        let mut files = Vec::new();
        for file in config.files {
            files.push(resolve_path(base_dir, &file)?);
        }

        Ok(Some(Self {
            family,
            files,
            weight: config.weight,
            style: config.style,
        }))
    }
}

#[derive(Debug, Clone, Default, Deserialize)]
struct BrandContactConfig {
    pub company: Option<LocalizedText>,
    pub address: Option<LocalizedText>,
    pub phone: Option<String>,
    pub email: Option<String>,
    pub website: Option<String>,
    #[serde(default)]
    pub extra: toml::value::Table,
}

impl BrandContactConfig {
    fn into_contact(self) -> BrandContact {
        BrandContact {
            company: self.company,
            address: self.address,
            phone: self.phone,
            email: self.email,
            website: self.website,
            extra: self.extra,
        }
    }
}

fn resolve_path(base_dir: &Path, path: &str) -> Result<PathBuf> {
    let expanded = expand_str_path(path)?;
    if expanded.is_absolute() {
        Ok(expanded)
    } else {
        Ok(base_dir.join(expanded))
    }
}

fn dedupe_languages(list: Vec<String>) -> Vec<String> {
    let mut seen = HashSet::new();
    let mut out = Vec::new();
    for lang in list {
        if lang.trim().is_empty() {
            continue;
        }
        if seen.insert(lang.clone()) {
            out.push(lang);
        }
    }
    out
}

fn load_brand_summary(path: &Path) -> Result<BrandSummary> {
    let brand = Brand::from_file(path)?;
    let name = brand.name_for(None).map(|s| s.to_string());
    Ok(BrandSummary {
        id: brand.id.clone(),
        name,
        languages: brand.languages.clone(),
        path: brand.source.file,
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;
    use tempfile::tempdir;

    fn sample_brand() -> String {
        r##"
id = "byteowlz"
default_language = "de"
languages = ["de", "en"]

[name]
en = "ByteOwlz"
de = "ByteOwlz GmbH"

[description]
en = "Default brand"
de = "Standardmarke"

[colors]
primary = "#0f172a"
accent = "#38bdf8"

[logos]
primary = "logo.svg"
monochrome = "assets/logo-mono.svg"

[typography.body]
family = "Inter"
files = ["fonts/Inter-Regular.ttf"]

[typography.heading]
family = "Inter Tight"

[contact]
company = { en = "ByteOwlz GmbH", de = "ByteOwlz GmbH" }
email = "hello@example.com"
"##
        .to_string()
    }

    #[test]
    fn parses_brand_with_languages_and_assets() {
        let dir = tempdir().unwrap();
        let root = dir.path();
        fs::write(root.join("logo.svg"), "").unwrap();
        fs::create_dir_all(root.join("assets")).unwrap();
        fs::write(root.join("assets/logo-mono.svg"), "").unwrap();
        fs::create_dir_all(root.join("fonts")).unwrap();
        fs::write(root.join("fonts/Inter-Regular.ttf"), "").unwrap();

        let brand_path = root.join("brand.toml");
        fs::write(&brand_path, sample_brand()).unwrap();

        let brand = Brand::from_file(&brand_path).unwrap();

        assert_eq!(brand.id, "byteowlz");
        assert_eq!(brand.default_language.as_deref(), Some("de"));
        assert_eq!(brand.languages, vec!["de".to_string(), "en".to_string()]);
        assert_eq!(brand.name_for(Some("en")), Some("ByteOwlz"));
        assert_eq!(brand.description_for(Some("fr")), Some("Standardmarke"));

        assert!(brand.logos.primary.is_some());
        assert!(brand.logos.monochrome.is_some());
        assert_eq!(brand.typography.body.as_ref().unwrap().family, "Inter");
        assert_eq!(brand.typography.body.as_ref().unwrap().files.len(), 1);
    }

    #[test]
    fn registry_discovers_brands_in_search_paths() {
        let dir = tempdir().unwrap();
        let root = dir.path();
        let brand_dir = root.join("byteowlz");
        fs::create_dir_all(&brand_dir).unwrap();
        fs::write(brand_dir.join("brand.toml"), sample_brand()).unwrap();

        let registry = BrandRegistry::new(vec![root.to_path_buf()]);
        let list = registry.list().unwrap();
        assert_eq!(list.len(), 1);
        assert_eq!(list[0].id, "byteowlz");
    }
}
