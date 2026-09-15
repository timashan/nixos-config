#!/usr/bin/env python3
"""Seed Helium's real profile with bookmarks and one-time CRX installs.

Helium stores user data in ~/.config/net.imput.helium. Extensions are installed
from local CRXs via External Extensions so welcome tabs do not reopen every launch.
"""

from __future__ import annotations

import hashlib
import json
import os
import pathlib
import shutil
import subprocess
import sys

HOME = pathlib.Path.home()
USER_DATA = HOME / ".config/net.imput.helium"
PROFILE = USER_DATA / "Default"
LOCK = USER_DATA / "SingletonLock"
LEGACY_PROFILE = HOME / ".config/helium/Default"
BOOKMARKS_HTML = pathlib.Path("/etc/nixos/local/bookmarks.html")
CONVERTER = pathlib.Path(os.environ["HELIUM_BOOKMARK_CONVERTER"])
STAMP = PROFILE / ".nixos-bookmarks.sha256"


def helium_running() -> bool:
    return LOCK.exists()


def install_external_extensions() -> None:
    src = os.environ.get("HELIUM_EXTENSIONS_DIR")
    if not src:
        return

    dest = USER_DATA / "External Extensions"
    dest.mkdir(parents=True, exist_ok=True)
    wanted = {path.name: path for path in pathlib.Path(src).glob("*.json")}
    for path in dest.glob("*.json"):
        if path.name not in wanted:
            path.unlink()
    for name, path in wanted.items():
        shutil.copyfile(path, dest / name)


def merge_prefs() -> None:
    PROFILE.mkdir(parents=True, exist_ok=True)
    prefs_path = PROFILE / "Preferences"
    prefs: dict = {}
    if prefs_path.exists():
        try:
            prefs = json.loads(prefs_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            return

    helium = prefs.setdefault("helium", {})
    helium["did_onboarding"] = True
    services = helium.setdefault("services", {})
    services["consented"] = True
    services["enabled"] = True
    services["ext_proxy"] = True
    helium_browser = helium.setdefault("browser", {})
    helium_browser["layout"] = 2  # Vertical tabs, Zen-style
    helium_browser["vertical_right_aligned"] = False
    helium_browser["zen_mode"] = True  # Frameless: hide chrome until hover
    prefs.setdefault("bookmark_bar", {})["show_on_all_tabs"] = True
    prefs.setdefault("session", {})["restore_on_startup"] = 1  # Continue where you left off
    browser = prefs.setdefault("browser", {})
    browser["check_default_browser"] = False
    browser["default_browser_infobar_last_declined"] = "99999999999999999"
    browser["default_browser_declined_count"] = 999
    prefs_path.write_text(json.dumps(prefs) + "\n", encoding="utf-8")


def import_bookmarks() -> None:
    if not BOOKMARKS_HTML.is_file():
        return

    digest = hashlib.sha256(BOOKMARKS_HTML.read_bytes()).hexdigest()
    bookmarks_path = PROFILE / "Bookmarks"
    if STAMP.is_file() and STAMP.read_text(encoding="utf-8").strip() == digest and bookmarks_path.is_file():
        return

    converted = subprocess.check_output(
        [sys.executable, str(CONVERTER), str(BOOKMARKS_HTML)],
        text=True,
    )
    bookmarks_path.write_text(converted, encoding="utf-8")
    STAMP.write_text(digest + "\n", encoding="utf-8")


def cleanup_legacy_profile() -> None:
    if not LEGACY_PROFILE.is_dir():
        return
    for name in ("Bookmarks", "Preferences", ".nixos-bookmarks.sha256"):
        path = LEGACY_PROFILE / name
        if path.is_file():
            path.unlink()


def main() -> int:
    USER_DATA.mkdir(parents=True, exist_ok=True)
    PROFILE.mkdir(parents=True, exist_ok=True)
    install_external_extensions()
    cleanup_legacy_profile()
    if helium_running():
        return 0
    merge_prefs()
    import_bookmarks()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
