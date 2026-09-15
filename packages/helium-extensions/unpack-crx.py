#!/usr/bin/env python3
"""Unpack a Chrome CRX2/CRX3 file into a directory."""

from __future__ import annotations

import io
import pathlib
import sys
import zipfile


def crx_zip_bytes(data: bytes) -> bytes:
    if data.startswith(b"Cr24"):
        header_size = int.from_bytes(data[8:12], "little")
        return data[12 + header_size :]
    if data.startswith(b"PK"):
        return data
    raise SystemExit("not a CRX or zip file")


def main() -> int:
    if len(sys.argv) != 3:
        print(f"usage: {sys.argv[0]} extension.crx DESTDIR", file=sys.stderr)
        return 2

    dest = pathlib.Path(sys.argv[2])
    dest.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(io.BytesIO(crx_zip_bytes(pathlib.Path(sys.argv[1]).read_bytes()))) as archive:
        archive.extractall(dest)
    if not (dest / "manifest.json").is_file():
        raise SystemExit(f"no manifest.json in {dest}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
