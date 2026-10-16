#!/usr/bin/env python3
"""Reject plaintext payloads in secrets/*.yaml without decrypting any value."""
from pathlib import Path
import sys
import yaml


def validate_text(text):
    if "PRIVATE KEY-----" in text or "AGE-SECRET-KEY-" in text:
        raise ValueError("private key material is present as plaintext")
    document = yaml.safe_load(text)
    if not isinstance(document, dict) or not isinstance(document.get("sops"), dict):
        raise ValueError("SOPS metadata is missing")
    if not document["sops"].get("mac") or not document["sops"].get("age"):
        raise ValueError("SOPS age recipients or integrity metadata are missing")

    def encrypted(value):
        if isinstance(value, dict):
            return all(encrypted(item) for item in value.values())
        if isinstance(value, list):
            return all(encrypted(item) for item in value)
        return isinstance(value, str) and value.startswith("ENC[AES256_GCM,") and value.endswith("]")

    if not all(encrypted(value) for key, value in document.items() if key != "sops"):
        raise ValueError("payload values must all be SOPS ciphertext")


def validate(path):
    validate_text(path.read_text())


def main():
    failed = False
    for filename in sys.argv[1:]:
        path = Path(filename)
        try:
            validate(path)
        except (OSError, ValueError, yaml.YAMLError) as error:
            # Report only the path and category, never parsed values.
            reason = str(error) if isinstance(error, ValueError) else "unreadable or invalid YAML"
            print(f"{path}: {reason}", file=sys.stderr)
            failed = True
    return int(failed)


if __name__ == "__main__":
    sys.exit(main())
