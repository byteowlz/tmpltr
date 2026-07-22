#!/usr/bin/env python3
"""Author missing benchmark templates with gemma (vLLM on hp-z8 via ssh tunnel).

Zero-LLM-API-cost authoring: for each template that is not verified-PASS,
gemma writes the sample JSON and/or the Typst template; each candidate is
compiled via bench/scripts/verify.sh and compile errors are fed back for up
to REPAIR_ROUNDS fixes. Run from the tmpltr repo root:

    ssh -f -N -L 18000:localhost:8000 hp-z8      # once
    python3 bench/scripts/gemma_author.py [--ids a,b] [--workers 4]
"""
import argparse
import json
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

import requests

BASE = "http://localhost:18000/v1"
MODEL = "gemma-4-26b-a4b"
REPAIR_ROUNDS = 4
ROOT = Path(".")

CONVENTIONS_DIGEST = """Hard rules for tmpltr benchmark Typst templates (Typst 0.14):
- Start with: #import "@local/tmpltr-lib:1.0.0": tmpltr-data, get
  then: #let data = tmpltr-data()
  and:  #let g(path, default: "") = get(data, path, default: default)
- EVERY data access via g("a.b") or dict.at("k", default: ...) — the template
  MUST compile with completely empty data `{}` (renders empty but valid page).
- Arrays: #let items = data.at("items", default: ()) and guard items.len() > 0.
- upper()/lower() are FUNCTIONS: upper(s), not s.upper(). No method chaining on
  possibly-none values. Guard all slices/indexing.
- Dates/IBANs are display strings, never parsed.
- No external images/network. Logos = text initials in a colored box.
- A4 page (tickets/receipts may use narrow custom sizes).
- German templates: German labels, dates like 18.07.2026, money as 1.234,56 €.
- Money helpers (copy if needed):
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
#let geld(x) = {
  let s = money(x, sym: "")
  s.replace(",", "X").replace(".", ",").replace("X", ".") + " €"
}
- Fonts installed: Arimo, Tinos, Cousine, Libertinus Serif, New Computer Modern,
  Adwaita Sans. Vary font/accent-color/header-layout so the document looks like
  a specific real-world document of its type."""


def llm(prompt, max_tokens=3600, temperature=0.4):
    r = requests.post(f"{BASE}/chat/completions", json={
        "model": MODEL,
        "messages": [{"role": "user", "content": prompt}],
        "temperature": temperature,
        "max_tokens": max_tokens,
    }, timeout=300)
    r.raise_for_status()
    return r.json()["choices"][0]["message"]["content"]


def extract_block(text, kind):
    m = re.findall(r"```(?:%s|json|typst|typ)?\s*\n(.*?)```" % kind, text, re.S)
    if m:
        return max(m, key=len).strip() + "\n"
    return text.strip() + "\n"


def verify(tid):
    r = subprocess.run(["./bench/scripts/verify.sh", tid], capture_output=True, text=True)
    err = ""
    ef = Path(f"/tmp/tmpltr-check/{tid}.err")
    if r.returncode != 0:
        err = (r.stdout + r.stderr).strip()
        if ef.exists():
            err += " | " + ef.read_text()[-500:]
    return r.returncode == 0, err[-800:]


def author_sample(meta, ref_sample):
    prompt = (
        f"Write ONE realistic sample JSON data instance for a document template.\n"
        f"Document type: {meta['title']} — {meta['desc']}\n"
        f"Locale: {'German (German names, addresses, companies, formats)' if meta['locale'] == 'de' else 'English/international'}\n"
        f"Field structure sketch (a{{b,c}} = object a with keys b,c; x[{{...}}] = array of objects):\n"
        f"{meta['fields']}\n\n"
        f"Example of the expected quality/completeness (DIFFERENT document type):\n"
        f"```json\n{ref_sample}\n```\n\n"
        f"Rules: complete realistic invented data, no placeholders like TODO/Lorem/XXX, "
        f"internally consistent numbers/dates, arrays with 3-8 items, numbers as JSON numbers, "
        f"dates as strings. Output ONLY the JSON object in a ```json code block."
    )
    return extract_block(llm(prompt, temperature=0.7), "json")


def author_typ(meta, sample_json, ref_typ):
    prompt = (
        f"{CONVENTIONS_DIGEST}\n\n"
        f"Reference template (a commercial invoice) showing exactly the required style:\n"
        f"```typst\n{ref_typ}\n```\n\n"
        f"Now write a COMPLETE new Typst template for this document type:\n"
        f"- id: {meta['id']}  title: {meta['title']}\n"
        f"- description: {meta['desc']}\n"
        f"- layout archetype: {meta['archetype']}\n"
        f"- locale: {meta['locale']}\n"
        f"It renders this JSON data (access ONLY these fields, all with defaults):\n"
        f"```json\n{sample_json}\n```\n"
        f"Make it look like a real {meta['title']} — choose a fitting font and layout, "
        f"NOT the same look as the reference invoice. Output ONLY the full Typst source "
        f"in a ```typst code block."
    )
    return extract_block(llm(prompt), "typst")


def repair_typ(typ_src, error):
    prompt = (
        f"This Typst 0.14 template fails to compile.\n\nError:\n{error}\n\n"
        f"Current source:\n```typst\n{typ_src}\n```\n\n"
        f"Rules that must hold: every data access needs a default "
        f"(get(data, \"a.b\", default: \"\") or .at(k, default: ...)); template must "
        f"compile with empty data {{}}; upper()/lower() are functions not methods; "
        f"guard array indexing. Return the FULL corrected file in a ```typst code block."
    )
    return extract_block(llm(prompt), "typst")


def process(tid, metas, ref_typ, ref_sample):
    meta = metas[tid]
    sp = ROOT / f"bench/data/samples/{tid}.json"
    tp = ROOT / f"bench/templates/{tid}.typ"
    op = ROOT / f"bench/templates/{tid}.toml"
    try:
        if not sp.exists():
            for _ in range(3):
                cand = author_sample(meta, ref_sample)
                try:
                    json.loads(cand)
                    sp.write_text(cand)
                    break
                except json.JSONDecodeError:
                    continue
            else:
                return f"FAIL {tid}: could not get valid sample JSON"
        else:
            try:
                json.loads(sp.read_text())
            except json.JSONDecodeError:
                return f"FAIL {tid}: existing sample JSON is invalid"

        subprocess.run([sys.executable, "bench/scripts/json2toml.py", str(sp), str(op)],
                       capture_output=True, check=True)

        if not tp.exists():
            tp.write_text(author_typ(meta, sp.read_text(), ref_typ))

        ok, err = verify(tid)
        rounds = 0
        while not ok and rounds < REPAIR_ROUNDS:
            rounds += 1
            tp.write_text(repair_typ(tp.read_text(), err))
            ok, err = verify(tid)
        if ok:
            return f"PASS {tid}" + (f" (after {rounds} repairs)" if rounds else "")
        return f"FAIL {tid}: {err[:200]}"
    except Exception as e:  # noqa: BLE001
        return f"FAIL {tid}: exception {str(e)[:200]}"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ids", default="")
    ap.add_argument("--workers", type=int, default=4)
    args = ap.parse_args()

    metas = {json.loads(l)["id"]: json.loads(l) for l in open("bench/manifest.jsonl")}
    ref_typ = Path("bench/templates/fin-invoice-en.typ").read_text()
    ref_sample = Path("bench/data/samples/fin-invoice-en.json").read_text()

    if args.ids:
        todo = [t for t in args.ids.split(",") if t]
    else:
        todo = []
        for tid in metas:
            ok, _ = (verify(tid) if (ROOT / f"bench/templates/{tid}.typ").exists()
                     and (ROOT / f"bench/templates/{tid}.toml").exists()
                     and (ROOT / f"bench/data/samples/{tid}.json").exists()
                     else (False, ""))
            if not ok:
                todo.append(tid)
    print(f"{len(todo)} templates to author/fix", flush=True)

    with ThreadPoolExecutor(max_workers=args.workers) as ex:
        futs = {ex.submit(process, t, metas, ref_typ, ref_sample): t for t in todo}
        for fut in as_completed(futs):
            print(fut.result(), flush=True)
    print("AUTHOR_DONE", flush=True)


if __name__ == "__main__":
    main()
