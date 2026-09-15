#!/usr/bin/env python3
"""Convert a Netscape bookmark HTML export to Chromium Bookmarks JSON."""

from __future__ import annotations

import json
import re
import sys
import uuid
from html import unescape
from typing import Any

WINDOWS_EPOCH_OFFSET_US = 11644473600000000

ROOT_GUIDS = {
    "bookmark_bar": "00000000-0000-4000-a000-000000000002",
    "other": "00000000-0000-4000-a000-000000000003",
    "synced": "00000000-0000-4000-a000-000000000004",
}

FOLDER_RE = re.compile(r"<DT><H3([^>]*)>(.*?)</H3>", re.I | re.S)
LINK_RE = re.compile(r"<DT><A HREF=\"([^\"]*)\"([^>]*)>(.*?)</A>", re.I | re.S)
ATTR_RE = re.compile(r"(\w+)\s*=\s*\"([^\"]*)\"")
TAG_RE = re.compile(r"<DT><H3|<DT><A HREF=|<DL>|<DL ><p>|</DL>", re.I)


def parse_attrs(raw: str) -> dict[str, str]:
    return {key.lower(): value for key, value in ATTR_RE.findall(raw)}


def chrome_time(unix_seconds: str | None) -> str:
    try:
        seconds = int(unix_seconds or "0")
    except ValueError:
        seconds = 0
    return str(seconds * 1_000_000 + WINDOWS_EPOCH_OFFSET_US)


def next_id(counter: list[int]) -> str:
    counter[0] += 1
    return str(counter[0])


def folder_node(name: str, attrs: dict[str, str], counter: list[int]) -> dict[str, Any]:
    return {
        "children": [],
        "date_added": chrome_time(attrs.get("add_date")),
        "date_modified": chrome_time(attrs.get("last_modified")),
        "guid": str(uuid.uuid4()),
        "id": next_id(counter),
        "name": unescape(name),
        "type": "folder",
    }


def url_node(href: str, name: str, attrs: dict[str, str], counter: list[int]) -> dict[str, Any]:
    return {
        "date_added": chrome_time(attrs.get("add_date")),
        "date_last_used": chrome_time(attrs.get("last_modified")),
        "guid": str(uuid.uuid4()),
        "id": next_id(counter),
        "name": unescape(re.sub(r"<[^>]+>", "", name)),
        "type": "url",
        "url": unescape(href),
    }


def parse_netscape(html: str) -> list[dict[str, Any]]:
    counter = [0]
    root: list[dict[str, Any]] = []
    stack: list[list[dict[str, Any]]] = [root]
    pending_folder: dict[str, Any] | None = None

    for match in TAG_RE.finditer(html):
        token = match.group(0)
        start = match.start()

        if token.upper().startswith("<DL"):
            if pending_folder is not None:
                stack[-1].append(pending_folder)
                stack.append(pending_folder["children"])
                pending_folder = None
            continue

        if token.upper().startswith("</DL"):
            if pending_folder is not None:
                stack[-1].append(pending_folder)
                pending_folder = None
            if len(stack) > 1:
                stack.pop()
            continue

        if token.upper().startswith("<DT><H3"):
            folder_match = FOLDER_RE.match(html, start)
            if not folder_match:
                continue
            if pending_folder is not None:
                stack[-1].append(pending_folder)
            pending_folder = folder_node(
                folder_match.group(2), parse_attrs(folder_match.group(1)), counter
            )
            continue

        link_match = LINK_RE.match(html, start)
        if not link_match:
            continue
        if pending_folder is not None:
            stack[-1].append(pending_folder)
            pending_folder = None
        stack[-1].append(
            url_node(
                link_match.group(1),
                link_match.group(3),
                parse_attrs(link_match.group(2)),
                counter,
            )
        )

    if pending_folder is not None:
        root.append(pending_folder)

    return root


def root_folder(key: str, name: str, children: list[dict[str, Any]], node_id: str) -> dict[str, Any]:
    return {
        "children": children,
        "date_added": chrome_time("0"),
        "date_modified": chrome_time("0"),
        "guid": ROOT_GUIDS[key],
        "id": node_id,
        "name": name,
        "type": "folder",
    }


def classify_roots(nodes: list[dict[str, Any]]) -> dict[str, list[dict[str, Any]]]:
    classified = {"bookmark_bar": [], "other": [], "synced": []}
    leftover: list[dict[str, Any]] = []

    for node in nodes:
        name = node.get("name", "").strip().lower()
        if node.get("type") != "folder":
            leftover.append(node)
            continue
        if "toolbar" in name or "bookmarks bar" in name:
            classified["bookmark_bar"].extend(node.get("children", []))
        elif name in {"other bookmarks", "other"}:
            classified["other"].extend(node.get("children", []))
        elif name in {"synced bookmarks", "mobile bookmarks"}:
            classified["synced"].extend(node.get("children", []))
        else:
            leftover.append(node)

    classified["other"].extend(leftover)
    return classified


def convert(html: str) -> dict[str, Any]:
    classified = classify_roots(parse_netscape(html))
    return {
        "checksum": "",
        "roots": {
            "bookmark_bar": root_folder(
                "bookmark_bar", "Bookmarks bar", classified["bookmark_bar"], "1"
            ),
            "other": root_folder("other", "Other bookmarks", classified["other"], "2"),
            "synced": root_folder("synced", "Mobile bookmarks", classified["synced"], "3"),
        },
        "version": 1,
    }


def main() -> int:
    if len(sys.argv) != 2:
        print(f"usage: {sys.argv[0]} BOOKMARKS.html", file=sys.stderr)
        return 2

    html = open(sys.argv[1], encoding="utf-8").read()
    json.dump(convert(html), sys.stdout, indent=3, ensure_ascii=False)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
