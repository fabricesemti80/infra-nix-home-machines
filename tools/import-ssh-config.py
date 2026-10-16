#!/usr/bin/env python3
"""Snapshot SSH config only. Dry-run by default; never read private identity files."""
import argparse
import glob
import json
from pathlib import Path
import re
import shlex
import sys

ROOT = Path(__file__).resolve().parents[1]
DIRECTIVE = re.compile(r"^\s*([A-Za-z][A-Za-z0-9]*)\s*(?:=\s*|\s+)(.*?)\s*$")
PRIVATE_KEY = re.compile(r"-----BEGIN (?:OPENSSH |RSA |EC |DSA |ENCRYPTED )?PRIVATE KEY-----")


class Importer:
    def __init__(self, ssh_dir, managed_prefix="~/.ssh/config.d/nix-imported"):
        self.ssh_dir = Path(ssh_dir).expanduser().resolve()
        self.managed_prefix = managed_prefix
        self.files = {}
        self.names = {}
        self.external_includes = []
        self.identities = []
        self.warnings = []
        self.active = set()

    def local(self, path):
        return path.is_relative_to(self.ssh_dir)

    def read(self, path):
        path = path.resolve()
        if path in self.active:
            raise ValueError(f"Recursive Include detected: {path}")
        if path in self.names:
            return self.names[path]
        if not self.local(path):
            raise ValueError("The root config must be within the supplied SSH directory")
        if path.stat().st_size > 1_000_000:
            raise ValueError(f"Refusing unusually large config file: {path}")
        text = path.read_text()
        if "\0" in text or PRIVATE_KEY.search(text):
            raise ValueError(f"Refusing non-config/private-key content: {path}")
        name = "config" if not self.names else f"include-{len(self.names):03}.conf"
        self.names[path] = name
        self.active.add(path)
        result = []
        for line in text.splitlines(keepends=True):
            match = DIRECTIVE.match(line)
            if not match:
                result.append(line)
                continue
            directive, value = match.groups()
            args = shlex.split(value, comments=True)
            if directive.lower() == "identityfile":
                self.identities.extend(args)
            if directive.lower() in {"proxycommand", "localcommand", "setenv", "match"}:
                self.warnings.append(f"Review {directive} in {path.name}; commands/environment may contain credentials or depend on local tools")
            if directive.lower() != "include":
                result.append(line)
                continue
            # Preserve individual Include positions and file ordering. Never flatten
            # Host/Match blocks: their parser scope must remain OpenSSH's scope.
            for pattern in args:
                expanded = Path(pattern).expanduser()
                if not expanded.is_absolute():
                    expanded = self.ssh_dir / expanded
                if "%" in pattern or "$" in pattern or not self.local(expanded.resolve()):
                    result.append(f'Include {json.dumps(pattern)}\n')
                    self.external_includes.append(pattern)
                    continue
                # OpenSSH orders wildcard matches by their names, not symlink targets.
                matches = [Path(p).resolve() for p in sorted(glob.glob(str(expanded)))]
                for child in matches:
                    if not self.local(child):
                        raise ValueError(f"Include symlink leaves SSH directory: {child}")
                    included = self.read(child)
                    result.append(f'Include "{self.managed_prefix}/{included}"\n')
                if not matches:
                    # Do not silently change an optional/dynamic Include into a
                    # frozen absence; keep it and report its dependency.
                    result.append(f'Include {json.dumps(pattern)}\n')
                    self.external_includes.append(pattern)
        self.active.remove(path)
        self.files[name] = "".join(result)
        return name

    def snapshot(self):
        self.read(self.ssh_dir / "config")
        return {
            "files": sorted(self.files),
            "identity_files_referenced_not_read": sorted(set(self.identities)),
            "external_includes": sorted(set(self.external_includes)),
            "warnings": sorted(set(self.warnings)),
        }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--label", required=True, help="Machine label, e.g. neo")
    parser.add_argument("--ssh-dir", type=Path, default=Path.home() / ".ssh")
    parser.add_argument("--write", action="store_true", help="Write a new snapshot for review")
    args = parser.parse_args()
    if not re.fullmatch(r"[A-Za-z0-9_-]+", args.label):
        parser.error("Label must be a simple machine name")
    try:
        importer = Importer(args.ssh_dir)
        manifest = importer.snapshot()
        destination = ROOT / "files" / "ssh" / "imported" / args.label
        if args.write:
            # Refuse overwrites, including existing symlinks.
            destination.mkdir(parents=True, exist_ok=False)
            for name, content in importer.files.items():
                (destination / name).write_text(content)
            (destination / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
            print(f"Wrote reviewable configuration to {destination}")
        else:
            print("Dry run. Nothing written. Use --write only after reviewing this report.")
        print(json.dumps(manifest, indent=2))
    except (OSError, ValueError) as error:
        parser.exit(1, f"Import stopped: {error}\n")


if __name__ == "__main__":
    main()
