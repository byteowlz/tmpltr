//! tmpltr - Template-based document generation CLI

use std::io::{self, IsTerminal, Write};
use std::process::ExitCode;

use clap::{CommandFactory, Parser};
use env_logger::fmt::WriteStyle;
use log::LevelFilter;

use tmpltr::cli::commands::{
    handle_add, handle_blocks, handle_brands, handle_compile, handle_config, handle_example,
    handle_get, handle_init, handle_new, handle_new_template, handle_recent, handle_set,
    handle_templates, handle_validate, handle_watch, Context,
};
use tmpltr::cli::{Cli, ColorOption, Command};
use tmpltr::error::Error;

fn main() -> ExitCode {
    match run() {
        Ok(()) => ExitCode::SUCCESS,
        Err(err) => {
            let code = err.exit_code();
            let _ = writeln!(io::stderr(), "error: {}", err);
            ExitCode::from(code as u8)
        }
    }
}

fn run() -> Result<(), Error> {
    let cli = Cli::parse();

    // Initialize logging
    init_logging(&cli)?;

    // Create context
    let mut ctx = Context::new(cli.common.clone())?;

    // Dispatch command
    match cli.command {
        Command::Init(args) => handle_init(&ctx, args),
        Command::New(args) => handle_new(&ctx, args),
        Command::Example(args) => handle_example(&ctx, args),
        Command::Compile(args) => handle_compile(&mut ctx, args),
        Command::Get(args) => handle_get(&mut ctx, args),
        Command::Set(args) => handle_set(&mut ctx, args),
        Command::Blocks(args) => handle_blocks(&mut ctx, args),
        Command::Validate(args) => handle_validate(&ctx, args),
        Command::Watch(args) => handle_watch(&mut ctx, args),
        Command::Templates(args) => handle_templates(&ctx, args),
        Command::Recent(args) => handle_recent(&ctx, args),
        Command::Brands { command } => handle_brands(&ctx, command),
        Command::Add { command } => handle_add(&ctx, command),
        Command::Config { command } => handle_config(&ctx, command),
        Command::NewTemplate(args) => handle_new_template(&ctx, args),
        Command::Completions { shell } => {
            let mut cmd = Cli::command();
            clap_complete::generate(shell, &mut cmd, "tmpltr", &mut io::stdout());
            Ok(())
        }
    }
}

fn init_logging(cli: &Cli) -> Result<(), Error> {
    let level = cli.common.log_level();

    if level == LevelFilter::Off {
        return Ok(());
    }

    let mut builder = env_logger::Builder::from_default_env();
    builder.filter_level(level);

    let use_colors = match cli.common.color {
        ColorOption::Always => true,
        ColorOption::Never => false,
        ColorOption::Auto => {
            !cli.common.no_color
                && std::env::var_os("NO_COLOR").is_none()
                && io::stderr().is_terminal()
        }
    };

    if use_colors {
        builder.write_style(WriteStyle::Auto);
    } else {
        builder.write_style(WriteStyle::Never);
    }

    builder
        .try_init()
        .map_err(|e| Error::Config(format!("initializing logger: {}", e)))?;

    Ok(())
}
