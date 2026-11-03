"""Add a managed import while keeping Vicinae's other writable preferences."""

import json
from pathlib import Path
import re
import sys
import tempfile
import os


def read_jsonc(text):
    # Match quoted strings first so URLs and comment-like string contents survive.
    strings = r'("(?:\\.|[^"\\])*")'
    text = re.sub(
        strings + r"|/\*.*?\*/|//[^\r\n]*",
        lambda match: match.group(1) or "",
        text,
        flags=re.DOTALL,
    )
    text = re.sub(
        strings + r"|,(?=\s*[}\]])",
        lambda match: match.group(1) or "",
        text,
    )
    return json.loads(text)


def configure(path, imported):
    data = read_jsonc(path.read_text()) if path.exists() else {}
    imports = data.setdefault("imports", [])
    if not isinstance(imports, list):
        raise ValueError("Vicinae imports must be an array")
    if imported in imports:
        return
    imports.append(imported)
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, delete=False) as temporary:
        try:
            json.dump(data, temporary, indent=2)
            temporary.write("\n")
            temporary.close()
            os.replace(temporary.name, path)
        finally:
            Path(temporary.name).unlink(missing_ok=True)


if __name__ == "__main__":
    configure(Path(sys.argv[1]), sys.argv[2])
