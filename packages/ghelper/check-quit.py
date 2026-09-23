#!/usr/bin/env python3
"""Exercise G-Helper's real tray Quit action in the current desktop session."""

import argparse
import json
import os
import subprocess
import tempfile
import time


def busctl(*args):
    return subprocess.run(
        ["busctl", "--user", "--json=short", *args],
        capture_output=True,
        text=True,
        timeout=5,
    )


def check_quit(binary):
    with tempfile.TemporaryFile(mode="w+") as log:
        proc = subprocess.Popen([binary], stdout=log, stderr=subprocess.STDOUT)
        try:
            bus = f"org.kde.StatusNotifierItem-{proc.pid}-0"
            deadline = time.monotonic() + 15
            while time.monotonic() < deadline:
                menu = busctl(
                    "get-property", bus, "/StatusNotifierItem",
                    "org.kde.StatusNotifierItem", "Menu",
                )
                if menu.returncode == 0:
                    path = json.loads(menu.stdout)["data"]
                    if isinstance(path, list):
                        path = path[0]
                    break
                if proc.poll() is not None:
                    raise RuntimeError("G-Helper exited before its tray appeared")
                time.sleep(0.2)
            else:
                raise RuntimeError("G-Helper's tray did not appear")

            layout = busctl(
                "call", bus, path, "com.canonical.dbusmenu",
                "GetLayout", "iias", "0", "2", "0",
            )
            layout.check_returncode()
            entries = json.loads(layout.stdout)["data"][1][2]
            quit_id = next(
                entry["data"][0] for entry in entries
                if entry["data"][1].get("label", {}).get("data") == "Quit"
            )
            time.sleep(8)
            # Shutdown can remove the bus service before its reply arrives.
            busctl(
                "call", bus, path, "com.canonical.dbusmenu", "Event",
                "isvu", str(quit_id), "clicked", "i", "0", "0",
            )
            code = proc.wait(timeout=10)
            log.seek(0)
            output = log.read()
            if code != 0 or "FATAL unhandled exception" in output:
                raise RuntimeError(f"Quit failed (exit {code}):\n{output}")
            return "Shutdown: handled canceled tray watcher" in output
        finally:
            if proc.poll() is None:
                proc.terminate()
                try:
                    proc.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    proc.kill()
                    proc.wait()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("binary", nargs="?", default="/run/current-system/sw/bin/ghelper")
    parser.add_argument("--attempts", type=int, default=10)
    args = parser.parse_args()
    if args.attempts < 1:
        parser.error("--attempts must be positive")
    if subprocess.run(
        ["pgrep", "-u", str(os.getuid()), "-x", "ghelper"],
        stdout=subprocess.DEVNULL,
    ).returncode == 0:
        parser.error("Quit the existing G-Helper instance before running this check")
    for attempt in range(args.attempts):
        handled = check_quit(args.binary)
        print(f"Quit {attempt + 1}: exit=0, cancellation handled={handled}", flush=True)
