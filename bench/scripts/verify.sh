#!/usr/bin/env bash
# Usage: bench/scripts/verify.sh <template-id>   (run from tmpltr repo root)
# Registers the template and runs both compile checks. Prints PASS or FAIL.
set -u
id="$1"
mkdir -p /tmp/tmpltr-check
cp -f "bench/templates/$id.typ" "bench/templates/$id.toml" ~/.local/share/tmpltr/templates/ || { echo "FAIL $id (missing files)"; exit 1; }
if ! tmpltr pipe "$id" -d "bench/data/samples/$id.json" -o "/tmp/tmpltr-check/$id.pdf" >/dev/null 2>/tmp/tmpltr-check/"$id".err; then
  echo "FAIL $id (sample): $(tail -c 300 /tmp/tmpltr-check/"$id".err)"
  exit 1
fi
if ! echo '{}' | tmpltr pipe "$id" -o "/tmp/tmpltr-check/$id-empty.pdf" >/dev/null 2>/tmp/tmpltr-check/"$id".err; then
  echo "FAIL $id (empty): $(tail -c 300 /tmp/tmpltr-check/"$id".err)"
  exit 1
fi
echo "PASS $id"
