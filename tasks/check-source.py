#!/usr/bin/env python3
"""Prevent Git flakes from silently omitting new source files; never stage them."""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE_PATHS = ["flake.nix", "flake.lock", "inventory.json", "files", "home",
                "hosts", "modules", "lib", "overlays", "users"]


def untracked_sources(root):
    paths = [name for name in SOURCE_PATHS if (root / name).exists()]
    result = subprocess.run(
        ["git", "ls-files", "--others", "--exclude-standard", "-z", "--", *paths],
        cwd=root, check=True, capture_output=True,
    )
    return [name for name in result.stdout.decode().split("\0") if name]


def main():
    unknown = untracked_sources(ROOT)
    if unknown:
        print("New source files are not visible to a Git flake. Review and git add them:",
              file=sys.stderr)
        for name in unknown:
            print(f"  {name}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
