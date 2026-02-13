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
