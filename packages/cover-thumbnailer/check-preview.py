"""Exercise the patched decoder without executing the thumbnailer's CLI main."""

import ast
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time

from gi.repository import Gio
from PIL import Image


source = Path(sys.argv[1])
tree = ast.parse(source.read_text())
definitions = [
    node
    for node in tree.body
    if isinstance(node, (ast.ClassDef, ast.FunctionDef))
    and node.name in {"Thumb", "search_previewable_files"}
]
namespace = dict(
    Image=Image,
    Gio=Gio,
    os=os,
    subprocess=subprocess,
    tempfile=tempfile,
    time=time,
    __file__=str(source),
)
for node in tree.body:
    if isinstance(node, ast.Assign) and any(
        isinstance(target, ast.Name)
        and target.id.startswith(("MAX_PREVIEW_", "PREVIEW_", "FOLDER_PREVIEW_"))
        for target in node.targets
    ):
        exec(compile(ast.Module(body=[node], type_ignores=[]), str(source), "exec"), namespace)
exec(compile(ast.Module(body=definitions, type_ignores=[]), str(source), "exec"), namespace)
Thumb = namespace["Thumb"]

with tempfile.TemporaryDirectory(prefix="thumbnail-check-") as directory:
    root = Path(directory)
    jpeg = root / "a.jpg"
    Image.new("RGB", (6000, 4000), (80, 110, 160)).save(jpeg)
    started = time.monotonic()
    tiles = Thumb([str(jpeg)] * 4)
    assert len(tiles.img) == 4
    assert all(max(image.size) <= namespace["PREVIEW_MAX_SIZE"] for image in tiles.img)
    assert all(image.mode == "RGBA" for image in tiles.img)
    print(f"Four 24-megapixel JPEG previews: {time.monotonic() - started:.3f}s")

    png = root / "b.png"
    Image.new("RGBA", (800, 800), (50, 80, 100, 128)).save(png)
    preview = Thumb.load_media_preview(str(png))
    assert preview.getpixel((0, 0))[3] == 128, "PNG transparency must survive"
    assert max(preview.size) <= namespace["PREVIEW_MAX_SIZE"]

    (root / ".hidden.jpg").touch()
    (root / "ignored.txt").touch()
    (root / "nested").mkdir()
    (root / "nested" / "child.jpg").touch()
    (root / "link.jpg").symlink_to(jpeg)
    found = namespace["search_previewable_files"](str(root))
    assert found == [str(jpeg), str(png)], found

    # A real stalled subprocess must time out, leave no temporary directory,
    # and allow later usable media to supply a preview.
    converter = root / "slow-converter"
    converter.write_text(f"#!{sys.executable}\nimport time\ntime.sleep(5)\n")
    converter.chmod(0o755)
    namespace["FFMPEG_THUMBNAILER"] = str(converter)
    namespace["PDFTOPPM"] = str(converter)
    namespace["PREVIEW_TIMEOUT_SECONDS"] = 0.05
    video = root / "stalled.mp4"
    video.touch()
    pdf = root / "stalled.pdf"
    pdf.touch()
    for media in (video, pdf):
        started = time.monotonic()
        tiles = Thumb([str(media), str(png)])
        assert len(tiles.img) == 1, "A stalled converter must not block a later image"
        assert time.monotonic() - started < 2

    namespace["FOLDER_PREVIEW_BUDGET_SECONDS"] = 0.1
    started = time.monotonic()
    tiles = Thumb([str(video)] * 32)
    assert not tiles.img
    assert time.monotonic() - started < 1, "Failures must respect the folder budget"

print("Preview size, transparency, file selection, converter timeouts, and budget checks passed")
