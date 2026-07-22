#!/usr/bin/env python3
"""Convert a sample JSON instance into the companion TOML content file.
Usage: json2toml.py bench/data/samples/<id>.json bench/templates/<id>.toml"""
import json
import sys


def dump(d, prefix=""):
    lines = []
    scalars = {k: v for k, v in d.items() if not isinstance(v, (dict, list))}
    tables = {k: v for k, v in d.items() if isinstance(v, dict)}
    arrays = {k: v for k, v in d.items() if isinstance(v, list)}
    for k, v in scalars.items():
        lines.append(f"{k} = {json.dumps(v, ensure_ascii=False)}")
    for k, v in arrays.items():
        if not v or not isinstance(v[0], dict):
            lines.append(f"{k} = {json.dumps(v, ensure_ascii=False)}")
    for k, v in tables.items():
        lines.append(f"\n[{prefix}{k}]")
        lines += dump(v, prefix=f"{prefix}{k}.")
    for k, v in arrays.items():
        if v and isinstance(v[0], dict):
            for item in v:
                lines.append(f"\n[[{prefix}{k}]]")
                lines += dump(item, prefix="")
    return lines


data = json.load(open(sys.argv[1]))
with open(sys.argv[2], "w") as f:
    f.write("\n".join(dump(data)) + "\n")
print(f"wrote {sys.argv[2]}")
