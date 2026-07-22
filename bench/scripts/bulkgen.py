#!/usr/bin/env python3
"""Bulk-generate realistic JSON document instances with gemma (vLLM, OpenAI API).

For each template: few-shot from the sample JSON, diversity hints from seeded
pools, structural validation against the sample (same keys recursively, arrays
non-empty & homogeneous, scalar types compatible with numeric coercion),
retries on failure. Output: generated/<id>.jsonl, one instance per line.

Usage: bulkgen.py --samples DIR --manifest manifest.jsonl --out DIR
                  [--ids id1,id2] [-k 50] [--workers 24]
"""
import argparse
import collections
import json
import random
import re
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

import requests

BASE_URL = "http://localhost:8000/v1"
MODEL = "gemma-4-26b-a4b"

INDUSTRIES = ["automotive supplier", "craft brewery", "dental practice", "wind energy",
              "software consultancy", "freight forwarding", "organic grocery chain",
              "architecture bureau", "plastics manufacturing", "regional bank",
              "physiotherapy clinic", "event agency", "printing house", "chemicals trading",
              "furniture retail", "cybersecurity startup", "municipal utility",
              "textile wholesale", "catering service", "engineering office",
              "pharma distribution", "car dealership", "property management",
              "recruitment agency", "food processing", "electronics repair",
              "publishing house", "solar installation", "logistics warehousing",
              "medical devices"]
REGIONS_DE = ["Ostwestfalen", "Ruhrgebiet", "Oberbayern", "Sachsen", "Rheinland",
              "Hamburg", "Berlin", "Franken", "Schwaben", "Niedersachsen",
              "Thüringen", "Baden", "Pfalz", "Holstein", "Brandenburg"]
REGIONS_EN = ["Greater Manchester", "Ohio", "Ontario", "Bavaria", "New South Wales",
              "Texas", "Scotland", "Ireland", "the Netherlands", "Denmark",
              "California", "Yorkshire", "New England", "Singapore", "Austria"]
QUIRKS = ["use rather high monetary amounts", "use small everyday amounts",
          "include many line items (8-14) where arrays allow", "keep arrays short (2-3 items)",
          "set the document in early 2025", "set the document in late 2026",
          "use a family-run business flavour", "use a large-corporation flavour",
          "include a person with a hyphenated surname", "include a non-Latin-origin personal name (transliterated)",
          "make some numeric values awkwardly precise", "use round numbers throughout"]


def structure_ok(sample, gen, path="$"):
    """Return (ok, coerced_value_or_error)."""
    if isinstance(sample, dict):
        if not isinstance(gen, dict):
            return False, f"{path}: expected object"
        if set(gen.keys()) != set(sample.keys()):
            missing = set(sample) - set(gen)
            extra = set(gen) - set(sample)
            return False, f"{path}: keys mismatch missing={sorted(missing)} extra={sorted(extra)}"
        out = {}
        for k in sample:
            ok, v = structure_ok(sample[k], gen[k], f"{path}.{k}")
            if not ok:
                return False, v
            out[k] = v
        return True, out
    if isinstance(sample, list):
        if not isinstance(gen, list) or len(gen) == 0:
            return False, f"{path}: expected non-empty array"
        if sample and isinstance(sample[0], dict):
            out = []
            for i, item in enumerate(gen):
                ok, v = structure_ok(sample[0], item, f"{path}[{i}]")
                if not ok:
                    return False, v
                out.append(v)
            return True, out
        return True, gen
    if gen is None:
        if isinstance(sample, str):
            return True, ""
        if isinstance(sample, (int, float)) and not isinstance(sample, bool):
            return True, 0
    if isinstance(sample, bool):
        if isinstance(gen, bool):
            return True, gen
        return False, f"{path}: expected bool"
    if isinstance(sample, (int, float)):
        if isinstance(gen, (int, float)) and not isinstance(gen, bool):
            return True, gen
        if isinstance(gen, str):
            s = gen.replace(",", "").replace("€", "").replace("$", "").strip()
            try:
                return True, float(s) if "." in s else int(s)
            except ValueError:
                pass
        return False, f"{path}: expected number, got {type(gen).__name__}"
    if isinstance(sample, str):
        if isinstance(gen, str):
            return True, gen
        if isinstance(gen, (int, float)):
            return True, str(gen)
        return False, f"{path}: expected string"
    return True, gen


def extract_json(text):
    text = text.strip()
    m = re.search(r"```(?:json)?\s*(.*?)```", text, re.S)
    if m:
        text = m.group(1).strip()
    start = text.find("{")
    if start < 0:
        raise ValueError("no JSON object")
    depth = 0
    for i, ch in enumerate(text[start:], start):
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return json.loads(text[start:i + 1])
    raise ValueError("unbalanced JSON")


def gen_prompt(meta, sample, rng):
    loc = "German (Germany): German names, addresses, companies, legal formats" \
        if meta.get("locale") == "de" else \
        "international English: names/addresses fitting the hinted region"
    hints = (f"- business/persona flavour: {rng.choice(INDUSTRIES)}\n"
             f"- region: {rng.choice(REGIONS_DE if meta.get('locale') == 'de' else REGIONS_EN)}\n"
             f"- {rng.choice(QUIRKS)}")
    return (
        f"You generate synthetic test data for document rendering. Below is a sample JSON "
        f"instance for the document type \"{meta.get('title', '')}\" ({meta.get('desc', '')}).\n\n"
        f"Sample:\n```json\n{json.dumps(sample, ensure_ascii=False, indent=1)}\n```\n\n"
        f"Generate ONE new instance:\n"
        f"- EXACTLY the same JSON structure and key names; do not add, drop, or rename keys\n"
        f"- completely different, internally consistent, realistic values (different people, "
        f"companies, numbers, dates, references); locale: {loc}\n"
        f"- arrays: keep the same item structure, vary the item count naturally\n"
        f"- keep value TYPES (numbers stay numbers, strings stay strings; keep date/number "
        f"string formats of the sample)\n"
        f"- fictional entities only; no real people\n"
        f"Diversity hints for this instance:\n{hints}\n\n"
        f"Output ONLY the JSON object, no commentary."
    )


def call(prompt, timeout=180):
    r = requests.post(f"{BASE_URL}/chat/completions", json={
        "model": MODEL,
        "messages": [{"role": "user", "content": prompt}],
        "temperature": 0.95,
        "top_p": 0.95,
        "max_tokens": 4096,
    }, timeout=timeout)
    r.raise_for_status()
    return r.json()["choices"][0]["message"]["content"]


def one_instance(meta, sample, seed):
    rng = random.Random(seed)
    err = ""
    for attempt in range(3):
        try:
            raw = call(gen_prompt(meta, sample, rng))
            obj = extract_json(raw)
            ok, coerced = structure_ok(sample, obj)
            if ok:
                return coerced, None
            err = coerced
        except Exception as e:  # noqa: BLE001
            err = str(e)[:200]
        rng = random.Random(seed * 1000 + attempt + 1)
    return None, err


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--samples", required=True)
    ap.add_argument("--manifest", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--ids", default="")
    ap.add_argument("-k", type=int, default=50)
    ap.add_argument("--workers", type=int, default=24)
    args = ap.parse_args()

    metas = {}
    for line in open(args.manifest):
        d = json.loads(line)
        metas[d["id"]] = d
    ids = [i for i in args.ids.split(",") if i] or sorted(metas)
    outdir = Path(args.out)
    outdir.mkdir(parents=True, exist_ok=True)

    for tid in ids:
        sp = Path(args.samples) / f"{tid}.json"
        if not sp.exists():
            print(f"SKIP {tid}: no sample", flush=True)
            continue
        sample = json.load(open(sp))
        outp = outdir / f"{tid}.jsonl"
        have = sum(1 for _ in open(outp)) if outp.exists() else 0
        if have >= args.k:
            print(f"DONE {tid}: {have} already", flush=True)
            continue
        fails = collections.Counter()
        with open(outp, "a") as f, ThreadPoolExecutor(max_workers=args.workers) as ex:
            futs = {ex.submit(one_instance, metas[tid], sample, 10_000 * hash(tid) % 10**6 + n): n
                    for n in range(have, args.k)}
            done = 0
            for fut in as_completed(futs):
                inst, err = fut.result()
                if inst is not None:
                    f.write(json.dumps(inst, ensure_ascii=False) + "\n")
                    done += 1
                else:
                    fails[err] += 1
        print(f"GEN {tid}: +{done} ok, {sum(fails.values())} failed"
              + (f" | top fail: {fails.most_common(1)}" if fails else ""), flush=True)
    print("BULKGEN_DONE", flush=True)


if __name__ == "__main__":
    main()
