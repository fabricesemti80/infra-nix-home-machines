#!/usr/bin/env python3
"""Create a new SOPS YAML from explicitly selected local keys, with no plaintext file."""
import argparse
from importlib import import_module
import json
import os
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path, help="New secrets/NAME.yaml file")
    parser.add_argument("--key", action="append", required=True, metavar="NAME=PATH")
    args = parser.parse_args()
    output = (ROOT / args.output).resolve()
    if output.parent != ROOT / "secrets" or output.suffix != ".yaml":
        parser.error("Output must be a direct secrets/*.yaml file")
    if output.exists() or output.is_symlink():
        parser.error("Refusing to replace an existing file; use sops edit to update it")
    values = {}
    for entry in args.key:
        name, separator, path = entry.partition("=")
        if not separator or not re.fullmatch(r"[A-Za-z0-9_-]+", name) or name in values:
            parser.error("Each --key needs a unique simple NAME=PATH")
        try:
            value = Path(path).expanduser().read_text()
        except OSError:
            parser.error(f"Cannot read explicitly selected identity {name}")
        if "PRIVATE KEY-----" not in value:
            parser.error(f"{name} is not a private key file")
        values[name] = value
    result = subprocess.run(
        ["sops", "--encrypt", "--input-type", "json", "--output-type", "yaml",
         "--filename-override", str(output.relative_to(ROOT)), "/dev/stdin"],
        cwd=ROOT, input=json.dumps(values).encode(), capture_output=True,
    )
    if result.returncode:
        # Avoid echoing parser diagnostics that could contain sensitive input.
        parser.exit(1, "Encryption failed; check .sops.yaml recipients and the sops installation. No output written.\n")
    try:
        import_module("check-secrets").validate_text(result.stdout.decode())
    except ValueError:
        parser.exit(1, "Encryption left plaintext or invalid metadata; refusing to write output.\n")
    output.parent.mkdir(exist_ok=True)
    fd = os.open(output, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
    with os.fdopen(fd, "wb") as handle:
        handle.write(result.stdout)
    print(f"Created {output.relative_to(ROOT)} with {len(values)} encrypted identities. Private values were not printed.")


if __name__ == "__main__":
    sys.exit(main())
