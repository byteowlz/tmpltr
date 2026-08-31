set positional-arguments

# Default recipe - show help
default:
    @just --list

# === Installation ===

# Install binary locally (default)
install:
    cargo install --path .

# Install with all features
install-all:
    cargo install --path . --all-features

# Uninstall binary
uninstall:
    cargo uninstall tmpltr

# === Building ===

# Debug build
build:
    cargo build

# Release build
build-release:
    cargo build --release

# Build with all features
build-all:
    cargo build --all-features

# Fast compile check
check:
    cargo check

# Clean build artifacts
clean:
    cargo clean

# === Testing ===

# Run tests
test:
    cargo test

# Run tests with all features
test-all:
    cargo test --all-features

# Run tests verbosely
test-v:
    cargo test -- --nocapture

# Run a specific test
test-one TEST:
    cargo test {{TEST}}

# === Code Quality ===

# Format all code
fmt:
    cargo fmt

# Check formatting
fmt-check:
    cargo fmt -- --check

# Run clippy linter
clippy:
    cargo clippy -- -D warnings

# Alias for clippy
lint: clippy

# Auto-fix clippy warnings
fix:
    cargo clippy --fix --allow-dirty

# Run all checks
check-all: fmt-check clippy test

# === Documentation ===

# Generate docs
docs:
    cargo doc --no-deps

# Generate and open docs
docs-open:
    cargo doc --no-deps --open

# === Dependencies ===

# Update all dependencies
update:
    cargo update

# Check for outdated dependencies
outdated:
    cargo outdated

# === Development ===

# Run the CLI in development mode; pass additional flags after `--`
run *args:
    cargo run -- {{args}}

# === Release ===

# Release build and show binary size
release: build-release
    @echo "Binary size:"
    @ls -lh target/release/tmpltr

# Tag and push a release
release-tag VERSION:
    git tag v{{VERSION}}
    git push --tags

# Publish tmpltr's agent skills to the canonical byteowlz skills repository.
sync-skills:
    #!/usr/bin/env bash
    set -euo pipefail
    target="${SKILLISSUES:-$HOME/byteowlz/skillissues}"
    test -d "$target/skills" || { echo "skillissues repo not found: $target" >&2; exit 1; }
    for skill in document_generation document_template_creation; do
        rm -rf "$target/skills/$skill"
        cp -a "skills/$skill" "$target/skills/"
    done
    just --justfile "$target/Justfile" update-readme
    git -C "$target" add skills/document_generation skills/document_template_creation README.md
    if [[ -n "$(git -C "$target" status --porcelain -- skills/document_generation skills/document_template_creation README.md)" ]]; then
        git -C "$target" commit -m "skills/tmpltr: sync from tmpltr" -- skills/document_generation skills/document_template_creation README.md
    else
        echo "tmpltr skills are already up to date"
    fi
