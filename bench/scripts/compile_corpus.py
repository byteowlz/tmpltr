#!/usr/bin/env python3
"""Compile every generated JSON instance to a PDF via tmpltr pipe.

Output layout: bench/data/pdfs/<template-id>/<template-id>-NNNN.pdf
(NNNN = 0-based line number in the matching generated/<id>.jsonl — the PDF's
gold data is exactly that JSONL line). Resumable: existing PDFs are skipped.

Usage (repo root): python3 bench/scripts/compile_corpus.py [--workers 8] [--ids a,b]
"""
import argparse
import json
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

GEN = Path("bench/data/generated")
OUT = Path("bench/data/pdfs")


def compile_one(tid, idx, line):
    out = OUT / tid / f"{tid}-{idx:04d}.pdf"
    if out.exists() and out.stat().st_size > 0:
        return None
    out.parent.mkdir(parents=True, exist_ok=True)
    r = subprocess.run(["tmpltr", "-q", "pipe", tid, "-o", str(out)],
                       input=line, capture_output=True, text=True)
    if r.returncode != 0:
        return f"{tid}-{idx:04d}: {r.stderr.strip()[-160:]}"
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--workers", type=int, default=8)
    ap.add_argument("--ids", default="")
    args = ap.parse_args()

    jobs = []
    only = set(i for i in args.ids.split(",") if i)
    for f in sorted(GEN.glob("*.jsonl")):
        tid = f.stem
        if only and tid not in only:
            continue
        for idx, line in enumerate(open(f)):
            if line.strip():
                jobs.append((tid, idx, line))
    print(f"{len(jobs)} documents to compile", flush=True)

    fails = []
    done = 0
    with ThreadPoolExecutor(max_workers=args.workers) as ex:
        futs = [ex.submit(compile_one, *j) for j in jobs]
        for fut in as_completed(futs):
            err = fut.result()
            done += 1
            if err:
                fails.append(err)
            if done % 500 == 0:
                print(f"  {done}/{len(jobs)} ({len(fails)} failed)", flush=True)
    print(f"COMPILED {done - len(fails)}/{len(jobs)}; {len(fails)} failures", flush=True)
    for e in fails[:20]:
        print("FAIL", e, flush=True)
    Path("/tmp/tmpltr-check/corpus_fails.json").write_text(json.dumps(fails))
    print("CORPUS_DONE", flush=True)


if __name__ == "__main__":
    main()
