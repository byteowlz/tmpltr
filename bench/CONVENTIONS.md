# Benchmark template authoring conventions

Every template in `bench/templates/` produces a realistic-looking real-world PDF
from JSON data. These documents feed an agentic-benchmark corpus: an LLM will
later fill them with generated data, so **templates must never crash on partial
data** and the JSON structure must exactly match `bench/manifest.jsonl`.

## Files per template (id from manifest)

- `bench/templates/<id>.typ` — the Typst template
- `bench/templates/<id>.toml` — companion content file with FULL realistic
  defaults (doubles as schema source and as one gold sample)
- `bench/data/samples/<id>.json` — one complete sample instance (same field
  structure as the manifest `fields` sketch; realistic values, no placeholders
  like "TODO" or "Lorem")

## Hard rules

1. **Every** data access uses `get(data, "path", default: ...)` from tmpltr-lib
   or `.at(k, default: ...)`. `echo '{}' | tmpltr pipe <id> -o /tmp/x.pdf`
   MUST succeed (renders an empty-ish but valid document).
2. Arrays: `let items = data.at("items", default: ())` and guard
   `if items.len() > 0`.
3. Dates/IBANs/etc. are display strings — never parse them.
4. No external images, no network. Logos are text/initials in a colored box
   (see reference). Deterministic output only.
5. A4 paper (except `ticket` archetype: use `width: 90mm, height: auto` or
   A5/DL where it fits the document type).
6. German templates use German labels, dates like `18.07.2026`, amounts like
   `1.234,56 €` (helper below). English templates use `$1,234.56` / `€1,234.56`
   per `currency` field.

## Money helpers (copy verbatim)

```typst
#let money(x, sym: "$") = {
  let v = calc.round(float(x), digits: 2)
  let neg = v < 0
  let a = calc.abs(v)
  let i = int(a)
  let c = int(calc.round((a - i) * 100))
  if c == 100 { i = i + 1; c = 0 }
  let s = str(i)
  let out = ""
  let n = s.clusters().len()
  for (k, ch) in s.clusters().enumerate() {
    out = out + ch
    let rem = n - k - 1
    if rem > 0 and calc.rem(rem, 3) == 0 { out = out + "," }
  }
  sym + (if neg { "-" } else { "" }) + out + "." + (if c < 10 { "0" } else { "" }) + str(c)
}
// German: 1.234,56 €
#let geld(x) = {
  let s = money(x, sym: "")
  s.replace(",", "X").replace(".", ",").replace("X", ".") + " €"
}
```

## Look & feel

Each template should look like a *specific* real document, not like its
siblings. Vary: font (Arimo, Tinos, Cousine, Libertinus Serif, New Computer
Modern, Adwaita Sans — these are installed), accent color, header layout
(logo-left / logo-right / centered / plain government header), rules/boxes,
footer density. Government/legal docs: sober, serif, file numbers in the
header. SaaS/IT: sans, colored accents. Receipts/tickets: monospace, narrow.
Payslips/statements: dense grids, small type (8–9pt).

Realism details worth adding where they fit: document numbers in headers,
page footers with company registration/bank lines, fold marks for DIN 5008
letters (`#place` a short line at left margin), signature lines, small-print
terms, "Seite 1 von 1".

## Registration + verification loop (must pass before a template counts)

```bash
cd ~/byteowlz/tmpltr
tmpltr add template bench/templates/<id>.typ
cp bench/templates/<id>.toml ~/.local/share/tmpltr/templates/
tmpltr pipe <id> -d bench/data/samples/<id>.json -o /tmp/tmpltr-check/<id>.pdf   # must exit 0
echo '{}' | tmpltr pipe <id> -o /tmp/tmpltr-check/<id>-empty.pdf                 # must exit 0
```

The reference implementation is `bench/templates/fin-invoice-en.typ` — read it
before writing your first template.

## tmpltr-lib quirks (discovered the hard way)

- `get(data, "x", default: ())` returns the STRING `"("` when the path is
  missing — never pass `()` or `false` as `get` defaults. For arrays use
  `#let garr(path) = { let v = get(data, path, default: none); if type(v) == array { v } else { () } }`;
  for booleans use `get(..., default: none) == true`.
