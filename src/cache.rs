//! Document cache for tmpltr
//!
//! Maintains an index of recently used documents and their editable blocks
//! for ergonomic commands like `from last` and title-based addressing.

use std::fs;
use std::path::{Path, PathBuf};

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

use crate::content::{BlockInfo, ContentFile};
use crate::error::{Error, Result};

const CACHE_FILENAME: &str = "documents.json";

/// A cached document entry
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CacheEntry {
    /// Absolute path to the content file
    pub file: PathBuf,
    /// Document metadata
    pub meta: CachedMeta,
    /// Indexed blocks
    pub blocks: Vec<BlockInfo>,
    /// Last access time
    pub last_used_at: DateTime<Utc>,
}

/// Cached document metadata
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CachedMeta {
    /// Template ID
    pub template_id: Option<String>,
    /// Template version
    pub template_version: Option<String>,
    /// Document title (from meta or quote.title)
    pub title: Option<String>,
    /// Quote number (if applicable)
    pub quote_number: Option<String>,
}

/// The document cache
#[derive(Debug)]
pub struct DocumentCache {
    /// Cache directory
    cache_dir: PathBuf,
    /// Cached entries
    entries: Vec<CacheEntry>,
}

impl DocumentCache {
    /// Load or create cache from disk
    pub fn load(cache_dir: impl AsRef<Path>) -> Result<Self> {
        let cache_dir = cache_dir.as_ref().to_path_buf();
        let cache_file = cache_dir.join(CACHE_FILENAME);

        let entries = if cache_file.exists() {
            let content = fs::read_to_string(&cache_file)
                .map_err(|e| Error::Cache(format!("reading cache file: {}", e)))?;
            serde_json::from_str(&content).unwrap_or_else(|_| Vec::new())
        } else {
            Vec::new()
        };

        Ok(Self { cache_dir, entries })
    }

    /// Save cache to disk
    pub fn save(&self) -> Result<()> {
        fs::create_dir_all(&self.cache_dir)
            .map_err(|e| Error::Cache(format!("creating cache directory: {}", e)))?;

        let cache_file = self.cache_dir.join(CACHE_FILENAME);
        let content = serde_json::to_string_pretty(&self.entries)?;
        fs::write(&cache_file, content)
            .map_err(|e| Error::Cache(format!("writing cache file: {}", e)))?;

        Ok(())
    }

    /// Update cache with a content file
    pub fn update(&mut self, content: &ContentFile) -> Result<()> {
        let abs_path = fs::canonicalize(&content.path)
            .map_err(|e| Error::Cache(format!("canonicalizing path: {}", e)))?;

        // Extract metadata
        let meta = CachedMeta {
            template_id: content.meta.template_id.clone(),
            template_version: content.meta.template_version.clone(),
            title: content
                .get("quote.title")
                .or_else(|| content.get("meta.title"))
                .and_then(|v| v.as_str())
                .map(|s| s.to_string()),
            quote_number: content
                .get("quote.number")
                .or_else(|| content.get("quote.angebot_nr"))
                .and_then(|v| v.as_str())
                .map(|s| s.to_string()),
        };

        // Collect blocks
        let blocks: Vec<BlockInfo> = content.list_blocks().into_iter().cloned().collect();

        // Create entry
        let entry = CacheEntry {
            file: abs_path.clone(),
            meta,
            blocks,
            last_used_at: Utc::now(),
        };

        // Remove existing entry for this file
        self.entries.retain(|e| e.file != abs_path);

        // Add new entry
        self.entries.push(entry);

        // Keep only recent entries (max 100)
        if self.entries.len() > 100 {
            self.entries
                .sort_by(|a, b| b.last_used_at.cmp(&a.last_used_at));
            self.entries.truncate(100);
        }

        self.save()
    }

    /// Get the most recently used document
    pub fn get_last(&self) -> Result<&CacheEntry> {
        self.entries
            .iter()
            .max_by_key(|e| e.last_used_at)
            .ok_or(Error::NoRecentDocument)
    }

    /// Get all cached entries, sorted by last used (most recent first)
    pub fn list(&self) -> Vec<&CacheEntry> {
        let mut entries: Vec<_> = self.entries.iter().collect();
        entries.sort_by(|a, b| b.last_used_at.cmp(&a.last_used_at));
        entries
    }

    /// Find a cached entry by file path
    pub fn find_by_path(&self, path: &Path) -> Option<&CacheEntry> {
        let abs_path = fs::canonicalize(path).ok()?;
        self.entries.iter().find(|e| e.file == abs_path)
    }

    /// Resolve a selector to a file path
    ///
    /// Selectors:
    /// - "last" - most recently used document
    /// - path - direct file path
    pub fn resolve_selector(&self, selector: &str) -> Result<PathBuf> {
        match selector {
            "last" => {
                let entry = self.get_last()?;
                Ok(entry.file.clone())
            }
            _ => {
                // Treat as file path
                let path = PathBuf::from(selector);
                if path.exists() {
                    Ok(path)
                } else {
                    Err(Error::FileNotFound { path })
                }
            }
        }
    }
}

/// Output format for recent documents listing
#[derive(Debug, Serialize)]
pub struct RecentDocument {
    pub file: PathBuf,
    pub template_id: Option<String>,
    pub template_version: Option<String>,
    pub meta_title: Option<String>,
    pub last_used_at: DateTime<Utc>,
}

impl From<&CacheEntry> for RecentDocument {
    fn from(entry: &CacheEntry) -> Self {
        Self {
            file: entry.file.clone(),
            template_id: entry.meta.template_id.clone(),
            template_version: entry.meta.template_version.clone(),
            meta_title: entry.meta.title.clone(),
            last_used_at: entry.last_used_at,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::tempdir;

    #[test]
    fn test_cache_roundtrip() {
        let dir = tempdir().unwrap();
        let cache = DocumentCache::load(dir.path()).unwrap();

        // Initially empty
        assert!(cache.entries.is_empty());
        assert!(cache.get_last().is_err());

        // Can save empty cache
        cache.save().unwrap();

        // Reload
        let cache2 = DocumentCache::load(dir.path()).unwrap();
        assert!(cache2.entries.is_empty());
    }
}
