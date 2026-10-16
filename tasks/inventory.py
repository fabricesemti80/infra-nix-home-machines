#!/usr/bin/env python3
"""Read the same inventory used to construct the flake's host outputs."""
import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load_inventory(root=ROOT):
    return json.loads((root / "inventory.json").read_text())


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["hosts", "target", "home", "show"])
    parser.add_argument("value", nargs="?")
    parser.add_argument("--enabled", action="store_true")
    args = parser.parse_args()
    hosts = load_inventory()
    if args.action == "hosts":
        print(" ".join(name for name, host in hosts.items()
                       if (not args.value or host["lane"] == args.value)
                       and (not args.enabled or host["enabled"])))
    elif args.action == "home":
        if args.value not in hosts:
            parser.error(f"Unknown host {args.value!r}")
        print(f"{hosts[args.value]['user']}@{args.value}")
    elif args.action == "target":
        target = hosts.get(args.value, {}).get("target")
        if not target:
            parser.error(f"No SSH target configured for {args.value!r}")
        print(target)
    else:
        for name, host in hosts.items():
            print(f"{name:12} {host['platform']:18} {host['user']:8} "
                  f"{host['target'] or 'local'}")


if __name__ == "__main__":
    main()
