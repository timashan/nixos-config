#!/usr/bin/env python3
"""Write Chromium External Extensions JSON for a local CRX."""

from __future__ import annotations

import json
import pathlib
import sys


def main() -> int:
    if len(sys.argv) != 4:
        print(f"usage: {sys.argv[0]} DEST.json CRX manifest.json", file=sys.stderr)
        return 2

    dest, crx, manifest_path = sys.argv[1], sys.argv[2], sys.argv[3]
    version = json.loads(pathlib.Path(manifest_path).read_text(encoding="utf-8"))["version"]
    pathlib.Path(dest).write_text(
        json.dumps(
            {
                "external_crx": crx,
                "external_version": version,
            }
        )
        + "\n",
        encoding="utf-8",
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
