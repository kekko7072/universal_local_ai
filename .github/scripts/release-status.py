#!/usr/bin/env python3
"""Compares each pinned package's manifest version with its registry.

Informational only: prints a Markdown table (to $GITHUB_STEP_SUMMARY when
set) and never fails, because publishing happens in each package's own
repository, never from this umbrella.
"""

from __future__ import annotations

import json
import os
import re
import sys
import tomllib
import urllib.request
from pathlib import Path


def fetch_json(url: str) -> dict | None:
    request = urllib.request.Request(url, headers={"User-Agent": "universal_local_ai-ci"})
    try:
        with urllib.request.urlopen(request, timeout=20) as response:
            return json.load(response)
    except Exception:
        return None


def manifest_versions() -> list[tuple[str, str, str | None, str]]:
    rows: list[tuple[str, str, str | None, str]] = []

    pubspec = Path("flutter_local_ai/pubspec.yaml")
    if pubspec.exists():
        match = re.search(r"^version:\s*(\S+)", pubspec.read_text(), re.M)
        rows.append(("flutter_local_ai", "pub.dev", match and match.group(1), "pub"))

    cargo = Path("rust_local_ai/Cargo.toml")
    if cargo.exists():
        rows.append(("rust_local_ai", "crates.io", tomllib.loads(cargo.read_text())["package"]["version"], "crates"))

    package_json = Path("typescript_local_ai/package.json")
    if package_json.exists():
        rows.append(("typescript_local_ai", "npm", json.loads(package_json.read_text())["version"], "npm"))

    pyproject = Path("python_local_ai/pyproject.toml")
    if pyproject.exists():
        rows.append(("python_local_ai", "PyPI", tomllib.loads(pyproject.read_text())["project"]["version"], "pypi"))

    return rows


def registry_versions(name: str, kind: str) -> list[str]:
    if kind == "pub":
        data = fetch_json(f"https://pub.dev/api/packages/{name}")
        return [v["version"] for v in data.get("versions", [])] if data else []
    if kind == "crates":
        data = fetch_json(f"https://crates.io/api/v1/crates/{name}")
        return [v["num"] for v in data.get("versions", []) if not v.get("yanked")] if data else []
    if kind == "npm":
        data = fetch_json(f"https://registry.npmjs.org/{name}")
        return list(data.get("versions", {})) if data else []
    if kind == "pypi":
        data = fetch_json(f"https://pypi.org/pypi/{name}/json")
        return list(data.get("releases", {})) if data else []
    return []


def main() -> int:
    lines = [
        "## Release status",
        "",
        "| Package | Registry | Pinned manifest version | Status |",
        "|---|---|---|---|",
    ]
    for name, registry, version, kind in manifest_versions():
        published = registry_versions(name, kind)
        if not version:
            status = "manifest has no version"
        elif version in published:
            status = "published"
        elif published:
            status = f"**unreleased** (registry has {', '.join(published[-3:])})"
        else:
            status = "**never published**"
        lines.append(f"| `{name}` | {registry} | `{version}` | {status} |")
    lines += ["", "Publishing runs in each package's repository; this repository never publishes."]
    text = "\n".join(lines) + "\n"
    print(text)
    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary:
        with open(summary, "a", encoding="utf-8") as handle:
            handle.write(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
