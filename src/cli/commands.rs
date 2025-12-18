//! Command implementations for tmpltr

use std::fs;
use std::io::{self, IsTerminal, Read};
use std::path::PathBuf;

use crate::brand::BrandRegistry;
use crate::cache::{DocumentCache, RecentDocument};
use crate::config::{load_or_create_config, write_default_config, ResolvedPaths};
use crate::content::{ContentBuilder, ContentFile};
use crate::error::{Error, Result};
use crate::template::{TemplateInfo, TemplateRegistry, TemplateSummary};
use crate::typst::{CompileOptions, OutputFormat, TypstCompiler};

use super::{
    AddCommand, AddFontArgs, AddLogoArgs, AddTemplateArgs, BlocksArgs, BrandsCommand,
    BrandsListArgs, BrandsNewArgs, BrandsShowArgs, BrandsValidateArgs, CommonOpts, CompileArgs,
    ConfigCommand, ExampleArgs, GetArgs, InitArgs, NewArgs, NewTemplateArgs, RecentArgs, SetArgs,
    TemplatesArgs, ValidateArgs, WatchArgs,
};

/// Runtime context for command execution
pub struct Context {
    pub common: CommonOpts,
    pub paths: ResolvedPaths,
    pub config: crate::config::AppConfig,
    pub cache: DocumentCache,
}

impl Context {
    /// Create a new context
    pub fn new(common: CommonOpts) -> Result<Self> {
        let mut paths = ResolvedPaths::discover(common.config.clone())?;
        let config = load_or_create_config(&paths)?;
        paths.apply_config(&config)?;

        if !common.dry_run {
            paths.ensure_directories()?;
        }

        let cache = DocumentCache::load(&paths.cache_dir)?;

        Ok(Self {
            common,
            paths,
            config,
            cache,
        })
    }

    /// Output result as JSON or human-readable
    pub fn output<T: serde::Serialize>(&self, value: &T, human: &str) -> Result<()> {
        if self.common.json {
            let json = serde_json::to_string_pretty(value)?;
            println!("{}", json);
        } else {
            println!("{}", human);
        }
        Ok(())
    }

    /// Output JSON only (for structured data)
    pub fn output_json<T: serde::Serialize>(&self, value: &T) -> Result<()> {
        if self.common.json {
            let json = serde_json::to_string_pretty(value)?;
            println!("{}", json);
        }
        Ok(())
    }
}

/// Handle init command
pub fn handle_init(ctx: &Context, args: InitArgs) -> Result<()> {
    let template = TemplateInfo::parse(&args.template)?;

    // Generate JSON schema if requested
    if let Some(ref schema_path) = args.schema {
        let schema = template.generate_schema();
        let schema_content = serde_json::to_string_pretty(&schema)?;

        if ctx.common.dry_run {
            log::info!("dry-run: would write schema to {}", schema_path.display());
            println!("{}", schema_content);
        } else {
            fs::write(schema_path, &schema_content).map_err(|e| {
                Error::Io(std::io::Error::new(
                    e.kind(),
                    format!("writing schema file {}: {}", schema_path.display(), e),
                ))
            })?;
        }
    }

    // Build content file
    let mut builder =
        ContentBuilder::new(&args.template.display().to_string()).template_id(&template.id);

    if let Some(ref version) = template.version {
        builder = builder.template_version(version);
    }

    let mut field_count = template.fields.len();
    let mut block_count = template.blocks.len();

    // Add fields from editable() calls
    for field in &template.fields {
        let value = field.default.clone().unwrap_or_default();
        builder = builder.field(&field.path, toml::Value::String(value));
    }

    // If --analyze-data, also extract data access patterns
    if args.analyze_data {
        let template_content = fs::read_to_string(&args.template).map_err(|e| {
            Error::Io(std::io::Error::new(
                e.kind(),
                format!("reading template {}: {}", args.template.display(), e),
            ))
        })?;
        let data_accesses = TemplateInfo::extract_data_access(&template_content);

        // Add fields from data access patterns (that weren't already added)
        let existing_paths: std::collections::HashSet<_> =
            template.fields.iter().map(|f| &f.path).collect();
        let existing_blocks: std::collections::HashSet<_> =
            template.blocks.iter().map(|b| &b.path).collect();

        for access in data_accesses {
            // Skip blocks - they're handled separately
            if access.path.starts_with("blocks.") {
                if !existing_blocks.contains(&access.path) {
                    let block_name = access.path.strip_prefix("blocks.").unwrap_or(&access.path);
                    // Check if it's a content access (e.g., blocks.intro.content)
                    if !block_name.contains('.') {
                        builder = builder.block(
                            block_name,
                            block_name.to_string(),
                            crate::content::BlockFormat::Markdown,
                            access.default.clone().unwrap_or_else(|| {
                                format!("# {}\n\nAdd content here.", block_name)
                            }),
                        );
                        block_count += 1;
                    }
                }
                continue;
            }

            // Skip already extracted fields
            if existing_paths.contains(&access.path) {
                continue;
            }

            // Add as field
            let value = access
                .default
                .clone()
                .unwrap_or_else(|| format!("<{}>", access.path));
            builder = builder.field(&access.path, toml::Value::String(value));
            field_count += 1;
        }
    }

    // Add blocks from editable-block() calls
    for block in &template.blocks {
        let title = block.title.clone().unwrap_or_else(|| block.path.clone());
        let content = block.default_content.clone().unwrap_or_default();
        builder = builder.block(
            block.path.strip_prefix("blocks.").unwrap_or(&block.path),
            title,
            block.format,
            content,
        );
    }

    let content = builder.build()?;

    // Determine output path
    let output_path = args.output.unwrap_or_else(|| {
        let stem = args
            .template
            .file_stem()
            .and_then(|s| s.to_str())
            .unwrap_or("content");
        PathBuf::from(format!("{}-content.toml", stem))
    });

    if ctx.common.dry_run {
        log::info!("dry-run: would write content to {}", output_path.display());
        println!("{}", content);
        return Ok(());
    }

    fs::write(&output_path, &content).map_err(|e| {
        Error::Io(std::io::Error::new(
            e.kind(),
            format!("writing content file {}: {}", output_path.display(), e),
        ))
    })?;

    let mut result = serde_json::json!({
        "status": "ok",
        "output": output_path,
        "fields": field_count,
        "blocks": block_count
    });

    if let Some(ref schema_path) = args.schema {
        result["schema"] = serde_json::json!(schema_path);
    }

    if args.analyze_data {
        result["analyze_data"] = serde_json::json!(true);
    }

    let message = if args.schema.is_some() {
        format!(
            "Generated {} with {} fields and {} blocks (schema also generated)",
            output_path.display(),
            field_count,
            block_count
        )
    } else {
        format!(
            "Generated {} with {} fields and {} blocks",
            output_path.display(),
            field_count,
            block_count
        )
    };

    ctx.output(&result, &message)
}

/// Handle new command
pub fn handle_new(ctx: &Context, args: NewArgs) -> Result<()> {
    let search_paths = vec![
        ctx.paths.templates_dir.clone(),
        PathBuf::from("."),
        PathBuf::from("./templates"),
    ];

    let registry = TemplateRegistry::new(search_paths);
    let template = registry.find(&args.template)?;

    // Use init logic with the found template
    let init_args = InitArgs {
        template: template.path,
        output: args.output,
        schema: None,
        update: false,
        content: None,
        analyze_data: false,
    };

    handle_init(ctx, init_args)
}

/// Handle example command
pub fn handle_example(ctx: &Context, args: ExampleArgs) -> Result<()> {
    let template_content = include_str!("../../typst_templates/example-template.typ");
    let content_content = include_str!("../../examples/example-content.toml");

    if !args.force {
        if args.template.exists() {
            return Err(Error::Content(format!(
                "template file {} already exists (use --force to overwrite)",
                args.template.display()
            )));
        }
        if args.content.exists() {
            return Err(Error::Content(format!(
                "content file {} already exists (use --force to overwrite)",
                args.content.display()
            )));
        }
    }

    if ctx.common.dry_run {
        log::info!(
            "dry-run: would write example template to {} and content to {}",
            args.template.display(),
            args.content.display()
        );
        return Ok(());
    }

    fs::write(&args.template, template_content).map_err(|e| {
        Error::Io(std::io::Error::new(
            e.kind(),
            format!("writing template {}: {}", args.template.display(), e),
        ))
    })?;

    fs::write(&args.content, content_content).map_err(|e| {
        Error::Io(std::io::Error::new(
            e.kind(),
            format!("writing content {}: {}", args.content.display(), e),
        ))
    })?;

    ctx.output(
        &serde_json::json!({
            "status": "ok",
            "template": args.template,
            "content": args.content
        }),
        &format!(
            "Wrote example template to {} and content to {}",
            args.template.display(),
            args.content.display()
        ),
    )
}

/// Handle compile command
pub fn handle_compile(ctx: &mut Context, args: CompileArgs) -> Result<()> {
    let content = ContentFile::load(&args.content)?;

    // Update cache
    ctx.cache.update(&content)?;

    let compiler = TypstCompiler::from_config(&ctx.config)?;

    // Load brand if specified
    let (brand_data, brand_font_paths) = load_brand_for_compile(ctx, args.brand.as_deref())?;

    // Handle --check mode
    if args.check {
        let options = CompileOptions {
            output: PathBuf::new(), // Not used in check mode
            format: None,
            brand_data,
            brand_font_paths,
            with_positions: false,
            experimental_html: false,
            check_only: true,
        };

        if ctx.common.dry_run {
            log::info!(
                "dry-run: would check {} for validity",
                args.content.display()
            );
            return Ok(());
        }

        compiler.compile(&content, &options)?;

        ctx.output(
            &serde_json::json!({
                "status": "ok",
                "valid": true,
                "content": args.content,
                "template": content.meta.template
            }),
            &format!(
                "{}: valid (template: {})",
                args.content.display(),
                content.meta.template
            ),
        )
    } else {
        let output = args.output.unwrap_or_else(|| {
            let stem = args
                .content
                .file_stem()
                .and_then(|s| s.to_str())
                .unwrap_or("output");
            PathBuf::from(format!("{}.pdf", stem))
        });

        let format = args.format.as_deref().and_then(OutputFormat::from_str);

        let options = CompileOptions {
            output,
            format,
            brand_data,
            brand_font_paths,
            with_positions: args.with_positions,
            experimental_html: args.experimental_html,
            check_only: false,
        };

        if ctx.common.dry_run {
            log::info!(
                "dry-run: would compile {} to {}",
                args.content.display(),
                options.output.display()
            );
            return Ok(());
        }

        let result = compiler.compile(&content, &options)?;

        if ctx.common.json {
            let json = serde_json::to_string_pretty(&result)?;
            println!("{}", json);
        } else {
            match result.output {
                Some(ref path) => println!("Compiled to {}", path.display()),
                None => {
                    if let Some(ref pages) = result.pages {
                        println!("Compiled {} pages", pages.len());
                    }
                }
            }
        }

        Ok(())
    }
}

/// Load brand data for compilation
fn load_brand_for_compile(
    ctx: &Context,
    brand_id: Option<&str>,
) -> Result<(Option<serde_json::Value>, Vec<PathBuf>)> {
    // Determine which brand to use: explicit flag > config default > none
    let brand_to_load = brand_id.or(ctx.config.brand.default.as_deref());

    let Some(brand_id) = brand_to_load else {
        return Ok((None, Vec::new()));
    };

    let search_paths = vec![ctx.paths.brands_dir.clone()];
    let registry = BrandRegistry::new(search_paths);

    let brand = registry.load(brand_id)?;

    // Extract font paths from brand
    let mut font_paths = Vec::new();

    // Add brand root directory for relative font paths
    font_paths.push(brand.source.root_dir.clone());

    // Add fonts directory if it exists
    let fonts_dir = brand.source.root_dir.join("fonts");
    if fonts_dir.exists() {
        font_paths.push(fonts_dir);
    }

    // Add specific font file directories
    for font_face in [
        &brand.typography.body,
        &brand.typography.heading,
        &brand.typography.mono,
    ]
    .into_iter()
    .flatten()
    {
        for file in &font_face.files {
            if let Some(parent) = file.parent() {
                if parent.exists() && !font_paths.contains(&parent.to_path_buf()) {
                    font_paths.push(parent.to_path_buf());
                }
            }
        }
    }

    // Build brand data JSON for injection
    let brand_data = serde_json::json!({
        "id": brand.id,
        "name": brand.name_for(None),
        "default_language": brand.default_language,
        "languages": brand.languages,
        "colors": {
            "primary": brand.colors.primary,
            "secondary": brand.colors.secondary,
            "accent": brand.colors.accent,
            "background": brand.colors.background,
            "text": brand.colors.text,
            "palette": brand.colors.palette
        },
        "logos": {
            "primary": brand.logos.primary.as_ref().map(|p| p.resolved.to_string_lossy()),
            "secondary": brand.logos.secondary.as_ref().map(|p| p.resolved.to_string_lossy()),
            "monochrome": brand.logos.monochrome.as_ref().map(|p| p.resolved.to_string_lossy()),
            "favicon": brand.logos.favicon.as_ref().map(|p| p.resolved.to_string_lossy())
        },
        "logo": brand.logos.primary.as_ref().map(|p| p.resolved.to_string_lossy()),
        "fonts": {
            "body": brand.typography.body.as_ref().map(|f| &f.family),
            "heading": brand.typography.heading.as_ref().map(|f| &f.family),
            "mono": brand.typography.mono.as_ref().map(|f| &f.family)
        },
        "contact": brand.contact.as_ref().map(|c| serde_json::json!({
            "company": c.company.as_ref().and_then(|t| t.resolve(None, brand.default_language.as_deref())),
            "address": c.address.as_ref().and_then(|t| t.resolve(None, brand.default_language.as_deref())),
            "phone": c.phone,
            "email": c.email,
            "website": c.website
        })),
        "root": brand.source.root_dir.to_string_lossy()
    });

    Ok((Some(brand_data), font_paths))
}

/// Handle get command
pub fn handle_get(ctx: &mut Context, args: GetArgs) -> Result<()> {
    let file_path = resolve_file(&ctx.cache, args.file, args.from.as_deref())?;
    let content = ContentFile::load(&file_path)?;

    // Update cache
    ctx.cache.update(&content)?;

    // Resolve path or title
    let path = content.resolve_path(&args.path_or_title)?;
    let value = content.get_content(&path)?;

    if ctx.common.json {
        let info = content.get_block_info(&path);
        let output = serde_json::json!({
            "id": path,
            "path": path,
            "title": info.and_then(|i| i.title.clone()),
            "format": info.and_then(|i| i.format.clone()),
            "type": info.map(|i| i.kind.as_str()),
            "content": value
        });
        println!("{}", serde_json::to_string_pretty(&output)?);
    } else {
        print!("{}", value);
        // Add newline if stdout is a terminal and value doesn't end with one
        if std::io::stdout().is_terminal() && !value.ends_with('\n') {
            println!();
        }
    }

    Ok(())
}

/// Handle set command
pub fn handle_set(ctx: &mut Context, args: SetArgs) -> Result<()> {
    let file_path = resolve_file(&ctx.cache, args.file, args.from.as_deref())?;

    // Read the value
    let value = if args.batch {
        // JSON batch mode - read from stdin
        let mut input = String::new();
        io::stdin().read_to_string(&mut input)?;
        return handle_batch_set(ctx, &file_path, &input);
    } else if let Some(ref file_input) = args.file_input {
        fs::read_to_string(file_input)?
    } else if let Some(ref val) = args.value {
        if val == "-" {
            let mut input = String::new();
            io::stdin().read_to_string(&mut input)?;
            input
        } else {
            val.clone()
        }
    } else {
        return Err(Error::Content("no value provided".to_string()));
    };

    // Load and modify content using toml_edit for preserving formatting
    let content_str = fs::read_to_string(&file_path)?;
    let content = ContentFile::parse(file_path.clone(), &content_str)?;

    // Resolve path
    let path = content.resolve_path(&args.path_or_title)?;

    // Parse as TOML document for editing
    let mut doc: toml_edit::DocumentMut = content_str
        .parse()
        .map_err(|e| Error::Content(format!("parsing TOML: {}", e)))?;

    // Set the value
    set_value_at_path(&mut doc, &path, &value)?;

    if ctx.common.dry_run {
        log::info!("dry-run: would set {} = {:?}", path, value);
        return Ok(());
    }

    // Write atomically
    let temp_path = file_path.with_extension("toml.tmp");
    fs::write(&temp_path, doc.to_string())?;
    fs::rename(&temp_path, &file_path)?;

    // Update cache
    let updated = ContentFile::load(&file_path)?;
    ctx.cache.update(&updated)?;

    ctx.output(
        &serde_json::json!({
            "status": "ok",
            "path": path,
            "file": file_path
        }),
        &format!("Set {}", path),
    )
}

/// Handle batch set from JSON
fn handle_batch_set(ctx: &mut Context, file_path: &PathBuf, input: &str) -> Result<()> {
    let updates: serde_json::Map<String, serde_json::Value> = serde_json::from_str(input)?;

    let content_str = fs::read_to_string(file_path)?;
    let mut doc: toml_edit::DocumentMut = content_str
        .parse()
        .map_err(|e| Error::Content(format!("parsing TOML: {}", e)))?;

    for (path, value) in &updates {
        let value_str = match value {
            serde_json::Value::String(s) => s.clone(),
            _ => value.to_string(),
        };
        set_value_at_path(&mut doc, path, &value_str)?;
    }

    if ctx.common.dry_run {
        log::info!("dry-run: would update {} paths", updates.len());
        return Ok(());
    }

    let temp_path = file_path.with_extension("toml.tmp");
    fs::write(&temp_path, doc.to_string())?;
    fs::rename(&temp_path, file_path)?;

    let updated = ContentFile::load(file_path)?;
    ctx.cache.update(&updated)?;

    ctx.output(
        &serde_json::json!({
            "status": "ok",
            "updated": updates.len(),
            "file": file_path
        }),
        &format!("Updated {} paths", updates.len()),
    )
}

/// Set a value at a path in a TOML document
fn set_value_at_path(doc: &mut toml_edit::DocumentMut, path: &str, value: &str) -> Result<()> {
    let parts: Vec<&str> = path.split('.').collect();

    // Navigate to parent
    let mut current: &mut toml_edit::Item = doc.as_item_mut();

    for (i, part) in parts.iter().enumerate() {
        if i == parts.len() - 1 {
            // Last part - set the value
            if let Some(table) = current.as_table_mut() {
                // Check if this is a block with content field
                if let Some(block) = table.get_mut(*part) {
                    if let Some(block_table) = block.as_table_mut() {
                        if block_table.contains_key("content") {
                            block_table["content"] = toml_edit::value(value);
                            return Ok(());
                        }
                    }
                }
                // Otherwise set directly
                table[*part] = toml_edit::value(value);
            } else {
                return Err(Error::PathNotFound {
                    path: path.to_string(),
                });
            }
        } else {
            // Navigate deeper
            if let Some(table) = current.as_table_mut() {
                if !table.contains_key(*part) {
                    table[*part] = toml_edit::Item::Table(toml_edit::Table::new());
                }
                current = &mut table[*part];
            } else {
                return Err(Error::PathNotFound {
                    path: path.to_string(),
                });
            }
        }
    }

    Ok(())
}

/// Handle blocks command
pub fn handle_blocks(ctx: &mut Context, args: BlocksArgs) -> Result<()> {
    let file_path = resolve_file(&ctx.cache, args.file, args.from.as_deref())?;
    let content = ContentFile::load(&file_path)?;

    // Update cache
    ctx.cache.update(&content)?;

    let blocks = content.list_blocks();

    if ctx.common.json {
        let json = serde_json::to_string_pretty(&blocks)?;
        println!("{}", json);
    } else {
        for block in blocks {
            let title = block.title.as_deref().unwrap_or("-");
            let kind = block.kind.as_str();
            println!("{} ({}) - {}", block.path, kind, title);
        }
    }

    Ok(())
}

/// Handle validate command
pub fn handle_validate(ctx: &Context, args: ValidateArgs) -> Result<()> {
    let content = ContentFile::load(&args.content)?;

    // Basic validation - check required fields
    let mut errors = Vec::new();

    // Check meta section
    if content.meta.template.is_empty() {
        errors.push("meta.template is required".to_string());
    }

    // Check blocks have valid format
    if let Some(blocks) = content.as_toml().get("blocks").and_then(|v| v.as_table()) {
        for (name, block) in blocks {
            if let Some(format) = block.get("format").and_then(|v| v.as_str()) {
                if !["markdown", "typst", "plain"].contains(&format) {
                    errors.push(format!(
                        "blocks.{}.format: invalid value '{}'",
                        name, format
                    ));
                }
            }
        }
    }

    if errors.is_empty() {
        ctx.output(
            &serde_json::json!({
                "status": "ok",
                "file": args.content
            }),
            &format!("{}: valid", args.content.display()),
        )
    } else {
        if ctx.common.json {
            let output = serde_json::json!({
                "status": "error",
                "kind": "validation_error",
                "errors": errors
            });
            println!("{}", serde_json::to_string_pretty(&output)?);
        } else {
            eprintln!("{}: validation failed", args.content.display());
            for error in &errors {
                eprintln!("  - {}", error);
            }
        }
        Err(Error::Validation(format!("{} errors", errors.len())))
    }
}

/// Handle watch command
pub fn handle_watch(ctx: &mut Context, args: WatchArgs) -> Result<()> {
    use notify::RecursiveMode;
    use notify_debouncer_mini::{new_debouncer, DebouncedEventKind};
    use std::sync::mpsc;
    use std::time::Duration;

    let debounce_ms = args.debounce.unwrap_or(ctx.config.output.watch_debounce_ms);

    let output = args.output.unwrap_or_else(|| {
        let stem = args
            .content
            .file_stem()
            .and_then(|s| s.to_str())
            .unwrap_or("output");
        PathBuf::from(format!("{}.pdf", stem))
    });

    let format = args.format.as_deref().and_then(OutputFormat::from_str);

    // Load brand if specified
    let (brand_data, brand_font_paths) = load_brand_for_compile(ctx, args.brand.as_deref())?;

    let options = CompileOptions {
        output: output.clone(),
        format,
        brand_data,
        brand_font_paths,
        with_positions: false,
        experimental_html: args.experimental_html,
        check_only: false,
    };

    // Initial compile
    let content = ContentFile::load(&args.content)?;
    let compiler = TypstCompiler::from_config(&ctx.config)?;

    match compiler.compile(&content, &options) {
        Ok(_) => {
            println!("Compiled to {}", output.display());

            // Open in default viewer if requested
            if args.open {
                match open_file(&output) {
                    Ok(_) => println!("Opened {} in default viewer", output.display()),
                    Err(e) => eprintln!("Warning: could not open file: {}", e),
                }
            }
        }
        Err(e) => eprintln!("Compilation error: {}", e),
    }

    // Set up file watcher
    let (tx, rx) = mpsc::channel();
    let mut debouncer = new_debouncer(Duration::from_millis(debounce_ms), tx)
        .map_err(|e| Error::Watch(format!("creating watcher: {}", e)))?;

    debouncer
        .watcher()
        .watch(&args.content, RecursiveMode::NonRecursive)
        .map_err(|e| Error::Watch(format!("watching file: {}", e)))?;

    println!("Watching {} for changes...", args.content.display());

    // Watch loop
    loop {
        match rx.recv() {
            Ok(Ok(events)) => {
                for event in events {
                    if matches!(event.kind, DebouncedEventKind::Any) {
                        match ContentFile::load(&args.content) {
                            Ok(content) => match compiler.compile(&content, &options) {
                                Ok(_) => println!("Recompiled to {}", output.display()),
                                Err(e) => eprintln!("Compilation error: {}", e),
                            },
                            Err(e) => eprintln!("Error loading content: {}", e),
                        }
                    }
                }
            }
            Ok(Err(e)) => {
                eprintln!("Watch error: {:?}", e);
            }
            Err(e) => {
                return Err(Error::Watch(format!("channel error: {}", e)));
            }
        }
    }
}

/// Handle templates command
pub fn handle_templates(ctx: &Context, args: TemplatesArgs) -> Result<()> {
    let search_paths = if let Some(path) = args.path {
        vec![path]
    } else {
        vec![
            ctx.paths.templates_dir.clone(),
            PathBuf::from("."),
            PathBuf::from("./templates"),
        ]
    };

    let registry = TemplateRegistry::new(search_paths);
    let templates = registry.list();

    if ctx.common.json {
        let summaries: Vec<TemplateSummary> = templates.iter().map(TemplateSummary::from).collect();
        let json = serde_json::to_string_pretty(&summaries)?;
        println!("{}", json);
    } else {
        if templates.is_empty() {
            println!("No templates found");
        } else {
            for template in templates {
                let desc = template.description.as_deref().unwrap_or("-");
                println!("{}: {}", template.id, desc);
            }
        }
    }

    Ok(())
}

/// Handle recent command
pub fn handle_recent(ctx: &Context, args: RecentArgs) -> Result<()> {
    let entries = ctx.cache.list();
    let limited: Vec<_> = entries.into_iter().take(args.limit).collect();

    if ctx.common.json {
        let docs: Vec<RecentDocument> = limited.iter().map(|e| RecentDocument::from(*e)).collect();
        let json = serde_json::to_string_pretty(&docs)?;
        println!("{}", json);
    } else {
        if limited.is_empty() {
            println!("No recent documents");
        } else {
            for entry in limited {
                let title = entry.meta.title.as_deref().unwrap_or("-");
                println!("{}: {}", entry.file.display(), title);
            }
        }
    }

    Ok(())
}

/// Handle config command
pub fn handle_config(ctx: &Context, command: ConfigCommand) -> Result<()> {
    match command {
        ConfigCommand::Show => {
            if ctx.common.json {
                let json = serde_json::to_string_pretty(&ctx.config)?;
                println!("{}", json);
            } else {
                let toml = toml::to_string_pretty(&ctx.config)?;
                println!("{}", toml);
            }
            Ok(())
        }
        ConfigCommand::Path => {
            println!("{}", ctx.paths.config_file.display());
            Ok(())
        }
        ConfigCommand::Reset => {
            if ctx.common.dry_run {
                log::info!(
                    "dry-run: would reset config at {}",
                    ctx.paths.config_file.display()
                );
                return Ok(());
            }
            write_default_config(&ctx.paths.config_file)?;
            ctx.output(
                &serde_json::json!({
                    "status": "ok",
                    "file": ctx.paths.config_file
                }),
                &format!("Reset config at {}", ctx.paths.config_file.display()),
            )
        }
    }
}

/// Handle add command
pub fn handle_add(ctx: &Context, command: AddCommand) -> Result<()> {
    match command {
        AddCommand::Logo(args) => handle_add_logo(ctx, args),
        AddCommand::Template(args) => handle_add_template(ctx, args),
        AddCommand::Font(args) => handle_add_font(ctx, args),
    }
}

/// Handle add logo command
fn handle_add_logo(ctx: &Context, args: AddLogoArgs) -> Result<()> {
    // Validate source exists
    if !args.source.exists() {
        return Err(Error::Content(format!(
            "source file not found: {}",
            args.source.display()
        )));
    }

    // Build destination path: brands/<brand>/logos/<name>
    let filename = args.name.unwrap_or_else(|| {
        args.source
            .file_name()
            .and_then(|n| n.to_str())
            .unwrap_or("logo")
            .to_string()
    });

    let dest_dir = ctx.paths.brands_dir.join(&args.brand).join("logos");
    let dest_path = dest_dir.join(&filename);

    // Check if destination exists
    if dest_path.exists() && !args.force {
        return Err(Error::Content(format!(
            "destination already exists: {} (use --force to overwrite)",
            dest_path.display()
        )));
    }

    if ctx.common.dry_run {
        log::info!(
            "dry-run: would copy {} to {}",
            args.source.display(),
            dest_path.display()
        );
        return ctx.output(
            &serde_json::json!({
                "status": "dry-run",
                "source": args.source,
                "destination": dest_path,
                "brand": args.brand
            }),
            &format!(
                "Would copy {} to {}",
                args.source.display(),
                dest_path.display()
            ),
        );
    }

    // Create directory and copy file
    fs::create_dir_all(&dest_dir).map_err(|e| {
        Error::Io(std::io::Error::new(
            e.kind(),
            format!("creating directory {}: {}", dest_dir.display(), e),
        ))
    })?;

    fs::copy(&args.source, &dest_path).map_err(|e| {
        Error::Io(std::io::Error::new(
            e.kind(),
            format!(
                "copying {} to {}: {}",
                args.source.display(),
                dest_path.display(),
                e
            ),
        ))
    })?;

    ctx.output(
        &serde_json::json!({
            "status": "ok",
            "source": args.source,
            "destination": dest_path,
            "brand": args.brand
        }),
        &format!("Added logo to {}", dest_path.display()),
    )
}

/// Handle add template command
fn handle_add_template(ctx: &Context, args: AddTemplateArgs) -> Result<()> {
    // Validate source exists
    if !args.source.exists() {
        return Err(Error::Content(format!(
            "source file not found: {}",
            args.source.display()
        )));
    }

    // Build destination path: templates/<name>
    let filename = args.name.unwrap_or_else(|| {
        args.source
            .file_name()
            .and_then(|n| n.to_str())
            .unwrap_or("template.typ")
            .to_string()
    });

    let dest_path = ctx.paths.templates_dir.join(&filename);

    // Check if destination exists
    if dest_path.exists() && !args.force {
        return Err(Error::Content(format!(
            "destination already exists: {} (use --force to overwrite)",
            dest_path.display()
        )));
    }

    if ctx.common.dry_run {
        log::info!(
            "dry-run: would copy {} to {}",
            args.source.display(),
            dest_path.display()
        );
        return ctx.output(
            &serde_json::json!({
                "status": "dry-run",
                "source": args.source,
                "destination": dest_path
            }),
            &format!(
                "Would copy {} to {}",
                args.source.display(),
                dest_path.display()
            ),
        );
    }

    // Create directory and copy file
    fs::create_dir_all(&ctx.paths.templates_dir).map_err(|e| {
        Error::Io(std::io::Error::new(
            e.kind(),
            format!(
                "creating directory {}: {}",
                ctx.paths.templates_dir.display(),
                e
            ),
        ))
    })?;

    fs::copy(&args.source, &dest_path).map_err(|e| {
        Error::Io(std::io::Error::new(
            e.kind(),
            format!(
                "copying {} to {}: {}",
                args.source.display(),
                dest_path.display(),
                e
            ),
        ))
    })?;

    ctx.output(
        &serde_json::json!({
            "status": "ok",
            "source": args.source,
            "destination": dest_path
        }),
        &format!("Added template to {}", dest_path.display()),
    )
}

/// Handle add font command
fn handle_add_font(ctx: &Context, args: AddFontArgs) -> Result<()> {
    // Validate source exists
    if !args.source.exists() {
        return Err(Error::Content(format!(
            "source file not found: {}",
            args.source.display()
        )));
    }

    // Build destination path: brands/<brand>/fonts/<name>
    let filename = args.name.unwrap_or_else(|| {
        args.source
            .file_name()
            .and_then(|n| n.to_str())
            .unwrap_or("font")
            .to_string()
    });

    let dest_dir = ctx.paths.brands_dir.join(&args.brand).join("fonts");
    let dest_path = dest_dir.join(&filename);

    // Check if destination exists
    if dest_path.exists() && !args.force {
        return Err(Error::Content(format!(
            "destination already exists: {} (use --force to overwrite)",
            dest_path.display()
        )));
    }

    if ctx.common.dry_run {
        log::info!(
            "dry-run: would copy {} to {}",
            args.source.display(),
            dest_path.display()
        );
        return ctx.output(
            &serde_json::json!({
                "status": "dry-run",
                "source": args.source,
                "destination": dest_path,
                "brand": args.brand
            }),
            &format!(
                "Would copy {} to {}",
                args.source.display(),
                dest_path.display()
            ),
        );
    }

    // Create directory and copy file
    fs::create_dir_all(&dest_dir).map_err(|e| {
        Error::Io(std::io::Error::new(
            e.kind(),
            format!("creating directory {}: {}", dest_dir.display(), e),
        ))
    })?;

    fs::copy(&args.source, &dest_path).map_err(|e| {
        Error::Io(std::io::Error::new(
            e.kind(),
            format!(
                "copying {} to {}: {}",
                args.source.display(),
                dest_path.display(),
                e
            ),
        ))
    })?;

    ctx.output(
        &serde_json::json!({
            "status": "ok",
            "source": args.source,
            "destination": dest_path,
            "brand": args.brand
        }),
        &format!("Added font to {}", dest_path.display()),
    )
}

/// Resolve file path from direct path or selector
fn resolve_file(
    cache: &DocumentCache,
    file: Option<PathBuf>,
    from: Option<&str>,
) -> Result<PathBuf> {
    if let Some(path) = file {
        return Ok(path);
    }

    if let Some(selector) = from {
        return cache.resolve_selector(selector);
    }

    Err(Error::Content(
        "no file specified. Use a file path or --from <selector>".to_string(),
    ))
}

/// Open a file with the system's default application
fn open_file(path: &std::path::Path) -> Result<()> {
    #[cfg(target_os = "macos")]
    {
        std::process::Command::new("open")
            .arg(path)
            .spawn()
            .map_err(|e| Error::Io(e))?;
    }

    #[cfg(target_os = "linux")]
    {
        std::process::Command::new("xdg-open")
            .arg(path)
            .spawn()
            .map_err(|e| Error::Io(e))?;
    }

    #[cfg(target_os = "windows")]
    {
        std::process::Command::new("cmd")
            .args(["/c", "start", ""])
            .arg(path)
            .spawn()
            .map_err(|e| Error::Io(e))?;
    }

    Ok(())
}

/// Handle brands command
pub fn handle_brands(ctx: &Context, command: BrandsCommand) -> Result<()> {
    match command {
        BrandsCommand::List(args) => handle_brands_list(ctx, args),
        BrandsCommand::Show(args) => handle_brands_show(ctx, args),
        BrandsCommand::New(args) => handle_brands_new(ctx, args),
        BrandsCommand::Validate(args) => handle_brands_validate(ctx, args),
    }
}

/// Handle brands list command
fn handle_brands_list(ctx: &Context, args: BrandsListArgs) -> Result<()> {
    let search_paths = if let Some(path) = args.path {
        vec![path]
    } else {
        vec![ctx.paths.brands_dir.clone()]
    };

    let registry = BrandRegistry::new(search_paths);
    let brands = registry.list()?;

    if ctx.common.json {
        let output: Vec<_> = brands
            .iter()
            .map(|b| {
                serde_json::json!({
                    "id": b.id,
                    "name": b.name,
                    "languages": b.languages,
                    "path": b.path
                })
            })
            .collect();
        let json = serde_json::to_string_pretty(&output)?;
        println!("{}", json);
    } else if brands.is_empty() {
        println!("No brands found");
    } else {
        for brand in brands {
            let name = brand.name.as_deref().unwrap_or("-");
            let langs = if brand.languages.is_empty() {
                String::new()
            } else {
                format!(" [{}]", brand.languages.join(", "))
            };
            println!("{}: {}{}", brand.id, name, langs);
        }
    }

    Ok(())
}

/// Handle brands show command
fn handle_brands_show(ctx: &Context, args: BrandsShowArgs) -> Result<()> {
    let search_paths = vec![ctx.paths.brands_dir.clone()];
    let registry = BrandRegistry::new(search_paths);
    let brand = registry.load(&args.brand)?;

    let lang = args.lang.as_deref();
    let name = brand.name_for(lang).unwrap_or("-");
    let description = brand.description_for(lang);

    if ctx.common.json {
        let output = serde_json::json!({
            "id": brand.id,
            "name": name,
            "description": description,
            "default_language": brand.default_language,
            "languages": brand.languages,
            "colors": {
                "primary": brand.colors.primary,
                "secondary": brand.colors.secondary,
                "accent": brand.colors.accent,
                "background": brand.colors.background,
                "text": brand.colors.text,
                "palette": brand.colors.palette
            },
            "logos": {
                "primary": brand.logos.primary.as_ref().map(|p| &p.resolved),
                "secondary": brand.logos.secondary.as_ref().map(|p| &p.resolved),
                "monochrome": brand.logos.monochrome.as_ref().map(|p| &p.resolved),
                "favicon": brand.logos.favicon.as_ref().map(|p| &p.resolved)
            },
            "typography": {
                "body": brand.typography.body.as_ref().map(|f| &f.family),
                "heading": brand.typography.heading.as_ref().map(|f| &f.family),
                "mono": brand.typography.mono.as_ref().map(|f| &f.family)
            },
            "contact": brand.contact.as_ref().map(|c| serde_json::json!({
                "company": c.company.as_ref().and_then(|t| t.resolve(lang, brand.default_language.as_deref())),
                "address": c.address.as_ref().and_then(|t| t.resolve(lang, brand.default_language.as_deref())),
                "phone": c.phone,
                "email": c.email,
                "website": c.website
            })),
            "path": brand.source.root_dir
        });
        let json = serde_json::to_string_pretty(&output)?;
        println!("{}", json);
    } else {
        println!("Brand: {}", brand.id);
        println!("Name: {}", name);
        if let Some(desc) = description {
            println!("Description: {}", desc);
        }
        println!("Languages: {}", brand.languages.join(", "));

        println!("\nColors:");
        if let Some(ref c) = brand.colors.primary {
            println!("  primary: {}", c);
        }
        if let Some(ref c) = brand.colors.secondary {
            println!("  secondary: {}", c);
        }
        if let Some(ref c) = brand.colors.accent {
            println!("  accent: {}", c);
        }

        println!("\nLogos:");
        if let Some(ref logo) = brand.logos.primary {
            println!("  primary: {}", logo.resolved.display());
        }
        if let Some(ref logo) = brand.logos.secondary {
            println!("  secondary: {}", logo.resolved.display());
        }
        if let Some(ref logo) = brand.logos.monochrome {
            println!("  monochrome: {}", logo.resolved.display());
        }

        println!("\nTypography:");
        if let Some(ref font) = brand.typography.body {
            println!("  body: {}", font.family);
        }
        if let Some(ref font) = brand.typography.heading {
            println!("  heading: {}", font.family);
        }
        if let Some(ref font) = brand.typography.mono {
            println!("  mono: {}", font.family);
        }

        if let Some(ref contact) = brand.contact {
            println!("\nContact:");
            if let Some(ref company) = contact.company {
                if let Some(c) = company.resolve(lang, brand.default_language.as_deref()) {
                    println!("  company: {}", c);
                }
            }
            if let Some(ref email) = contact.email {
                println!("  email: {}", email);
            }
            if let Some(ref website) = contact.website {
                println!("  website: {}", website);
            }
        }

        println!("\nPath: {}", brand.source.root_dir.display());
    }

    Ok(())
}

/// Handle brands new command
fn handle_brands_new(ctx: &Context, args: BrandsNewArgs) -> Result<()> {
    let output_dir = args
        .output
        .unwrap_or_else(|| ctx.paths.brands_dir.join(&args.id));

    let brand_file = output_dir.join("brand.toml");

    // Check if brand already exists
    if brand_file.exists() && !args.force {
        return Err(Error::Content(format!(
            "brand already exists at {} (use --force to overwrite)",
            brand_file.display()
        )));
    }

    let name = args.name.unwrap_or_else(|| args.id.clone());
    let primary_color = args.primary_color.unwrap_or_else(|| "#0f172a".to_string());

    let brand_content = format!(
        r##"# Brand configuration for {name}

id = "{id}"
default_language = "en"
languages = ["en"]

[name]
en = "{name}"

[description]
en = "Brand description"

[colors]
primary = "{primary_color}"
secondary = "#64748b"
accent = "#38bdf8"
background = "#ffffff"
text = "#0b1120"

[logos]
# primary = "logo.svg"
# monochrome = "logo-mono.svg"

[typography.body]
family = "Inter"
# files = ["fonts/Inter-Regular.ttf"]

[typography.heading]
family = "Inter"
# files = ["fonts/Inter-Bold.ttf"]

[contact]
# company = {{ en = "{name}" }}
# email = "hello@example.com"
# website = "https://example.com"
"##,
        id = args.id,
        name = name,
        primary_color = primary_color
    );

    if ctx.common.dry_run {
        log::info!("dry-run: would create brand at {}", output_dir.display());
        println!("{}", brand_content);
        return Ok(());
    }

    // Create directory structure
    fs::create_dir_all(&output_dir).map_err(|e| {
        Error::Io(std::io::Error::new(
            e.kind(),
            format!("creating brand directory {}: {}", output_dir.display(), e),
        ))
    })?;

    // Create subdirectories
    fs::create_dir_all(output_dir.join("logos")).ok();
    fs::create_dir_all(output_dir.join("fonts")).ok();

    // Write brand.toml
    fs::write(&brand_file, brand_content).map_err(|e| {
        Error::Io(std::io::Error::new(
            e.kind(),
            format!("writing brand file {}: {}", brand_file.display(), e),
        ))
    })?;

    ctx.output(
        &serde_json::json!({
            "status": "ok",
            "brand_id": args.id,
            "path": output_dir
        }),
        &format!("Created brand '{}' at {}", args.id, output_dir.display()),
    )
}

/// Handle brands validate command
fn handle_brands_validate(ctx: &Context, args: BrandsValidateArgs) -> Result<()> {
    let search_paths = vec![ctx.paths.brands_dir.clone()];
    let registry = BrandRegistry::new(search_paths);

    // Try to load the brand - this validates basic structure
    let brand = match registry.load(&args.brand) {
        Ok(b) => b,
        Err(e) => {
            if ctx.common.json {
                let output = serde_json::json!({
                    "status": "error",
                    "valid": false,
                    "brand": args.brand,
                    "errors": [e.to_string()]
                });
                println!("{}", serde_json::to_string_pretty(&output)?);
            } else {
                eprintln!("{}: validation failed", args.brand);
                eprintln!("  - {}", e);
            }
            return Err(e);
        }
    };

    let mut errors = Vec::new();
    let mut warnings = Vec::new();

    // Validate required fields
    if brand.id.is_empty() {
        errors.push("id is required".to_string());
    }

    if brand.name.is_empty() {
        errors.push("name is required".to_string());
    }

    // Validate colors (hex format)
    let color_regex =
        regex::Regex::new(r"^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$").unwrap();
    for (name, color) in [
        ("primary", &brand.colors.primary),
        ("secondary", &brand.colors.secondary),
        ("accent", &brand.colors.accent),
        ("background", &brand.colors.background),
        ("text", &brand.colors.text),
    ] {
        if let Some(c) = color {
            if !color_regex.is_match(c) {
                warnings.push(format!("colors.{}: '{}' is not a valid hex color", name, c));
            }
        }
    }

    // Check referenced files if --check-files
    if args.check_files {
        // Check logo files
        for (name, logo) in [
            ("primary", &brand.logos.primary),
            ("secondary", &brand.logos.secondary),
            ("monochrome", &brand.logos.monochrome),
            ("favicon", &brand.logos.favicon),
        ] {
            if let Some(asset) = logo {
                if !asset.resolved.exists() {
                    errors.push(format!(
                        "logos.{}: file not found: {}",
                        name,
                        asset.resolved.display()
                    ));
                }
            }
        }

        // Check font files
        for (name, font) in [
            ("body", &brand.typography.body),
            ("heading", &brand.typography.heading),
            ("mono", &brand.typography.mono),
        ] {
            if let Some(face) = font {
                for file in &face.files {
                    if !file.exists() {
                        errors.push(format!(
                            "typography.{}.files: file not found: {}",
                            name,
                            file.display()
                        ));
                    }
                }
            }
        }
    }

    // Build result
    let valid = errors.is_empty();

    if ctx.common.json {
        let output = serde_json::json!({
            "status": if valid { "ok" } else { "error" },
            "valid": valid,
            "brand": brand.id,
            "path": brand.source.file,
            "errors": errors,
            "warnings": warnings
        });
        println!("{}", serde_json::to_string_pretty(&output)?);
    } else {
        if valid {
            println!(
                "{}: valid (id: {}, languages: {})",
                brand.source.file.display(),
                brand.id,
                brand.languages.join(", ")
            );
            for warning in &warnings {
                println!("  warning: {}", warning);
            }
        } else {
            eprintln!("{}: validation failed", brand.source.file.display());
            for error in &errors {
                eprintln!("  - {}", error);
            }
            for warning in &warnings {
                eprintln!("  warning: {}", warning);
            }
        }
    }

    if valid {
        Ok(())
    } else {
        Err(Error::Validation(format!("{} errors", errors.len())))
    }
}

/// Handle new-template command
pub fn handle_new_template(ctx: &Context, args: NewTemplateArgs) -> Result<()> {
    let output_dir = args.output.unwrap_or_else(|| PathBuf::from("."));

    let template_filename = format!("{}.typ", args.name);
    let content_filename = format!("{}-content.toml", args.name);
    let template_path = output_dir.join(&template_filename);
    let content_path = output_dir.join(&content_filename);

    // Check if files exist
    if !args.force {
        if template_path.exists() {
            return Err(Error::Content(format!(
                "template file {} already exists (use --force to overwrite)",
                template_path.display()
            )));
        }
        if content_path.exists() {
            return Err(Error::Content(format!(
                "content file {} already exists (use --force to overwrite)",
                content_path.display()
            )));
        }
    }

    let description = args
        .description
        .unwrap_or_else(|| format!("Template for {}", args.name));

    // Generate template content
    let template_content = format!(
        r##"// @description: {description}
// @version: {version}

#import "@local/tmpltr-lib:1.0.0": editable, editable-block, tmpltr-data, md, get

#let data = tmpltr-data()

#set page(paper: "a4", margin: 2.5cm)
#set text(font: get(data, "brand.fonts.body", default: "Inter"), size: 11pt)

// Header with optional logo
#let logo_path = get(data, "brand.logo", default: get(data, "brand.logos.primary", default: none))
#if logo_path != none and logo_path != "" {{
  align(left)[#image(logo_path, width: 3cm)]
}}

#v(1cm)

// Document title
#align(center)[
  #text(size: 24pt, weight: "bold")[
    #editable("document.title", get(data, "document.title", default: "Document Title"), type: "text")
  ]
]

#v(0.5cm)

// Document subtitle
#align(center)[
  #text(size: 14pt, fill: rgb("#64748b"))[
    #editable("document.subtitle", get(data, "document.subtitle", default: "Subtitle"), type: "text")
  ]
]

#v(1cm)

// Main content blocks
#editable-block("blocks.introduction", title: "Introduction", format: "markdown")[
  #md(get(data, "blocks.introduction.content", default: "Add your introduction here."))
]

#v(0.5cm)

#editable-block("blocks.content", title: "Main Content", format: "markdown")[
  #md(get(data, "blocks.content.content", default: "Add your main content here."))
]

#v(0.5cm)

#editable-block("blocks.conclusion", title: "Conclusion", format: "markdown")[
  #md(get(data, "blocks.conclusion.content", default: "Add your conclusion here."))
]
"##,
        description = description,
        version = args.version
    );

    // Generate content file
    let content_content = format!(
        r##"# Content for {name} template

[meta]
template = "{name}.typ"
template_id = "{name}"
template_version = "{version}"

[brand]
logo = ""

[brand.colors]
primary = "#0f172a"
accent = "#38bdf8"

[document]
title = "Document Title"
subtitle = "Subtitle"

[blocks.introduction]
title = "Introduction"
format = "markdown"
content = "Add your introduction here."

[blocks.content]
title = "Main Content"
format = "markdown"
content = "Add your main content here."

[blocks.conclusion]
title = "Conclusion"
format = "markdown"
content = "Add your conclusion here."
"##,
        name = args.name,
        version = args.version
    );

    if ctx.common.dry_run {
        log::info!(
            "dry-run: would create template at {} and content at {}",
            template_path.display(),
            content_path.display()
        );
        println!("=== {} ===", template_path.display());
        println!("{}", template_content);
        println!();
        println!("=== {} ===", content_path.display());
        println!("{}", content_content);
        return Ok(());
    }

    // Create output directory if needed
    if !output_dir.exists() {
        fs::create_dir_all(&output_dir).map_err(|e| {
            Error::Io(std::io::Error::new(
                e.kind(),
                format!("creating output directory {}: {}", output_dir.display(), e),
            ))
        })?;
    }

    // Write files
    fs::write(&template_path, template_content).map_err(|e| {
        Error::Io(std::io::Error::new(
            e.kind(),
            format!("writing template {}: {}", template_path.display(), e),
        ))
    })?;

    fs::write(&content_path, content_content).map_err(|e| {
        Error::Io(std::io::Error::new(
            e.kind(),
            format!("writing content {}: {}", content_path.display(), e),
        ))
    })?;

    ctx.output(
        &serde_json::json!({
            "status": "ok",
            "template": template_path,
            "content": content_path
        }),
        &format!(
            "Created template {} and content {}",
            template_path.display(),
            content_path.display()
        ),
    )
}
