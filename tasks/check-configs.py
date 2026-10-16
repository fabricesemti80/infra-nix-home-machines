#!/usr/bin/env python3
"""Evaluate native system/home derivations; some themes build during evaluation."""
import argparse
import platform
import subprocess
from inventory import ROOT, load_inventory


def native_platform():
    machine = {"arm64": "aarch64", "AMD64": "x86_64"}.get(
        platform.machine(), platform.machine())
    return f"{machine}-{'darwin' if platform.system() == 'Darwin' else 'linux'}"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host", help="Evaluate one native host (CI matrix)")
    args = parser.parse_args()
    inventory = load_inventory()
    if args.host and args.host not in inventory:
        parser.error(f"Unknown host {args.host!r}")
    native = native_platform()
    selected = {name: host for name, host in inventory.items()
                if (not args.host or name == args.host) and host["platform"] == native}
    if args.host and not selected:
        parser.error(f"{args.host} requires {inventory[args.host]['platform']}; running on {native}")
    if not selected:
        print(f"No native host on {native}; CI evaluates hosts on their own platforms.")
    for name, host in selected.items():
        if host["lane"] == "darwin":
            system = f'darwinConfigurations."{name}".system.drvPath'
        else:
            system = f'nixosConfigurations."{name}".config.system.build.toplevel.drvPath'
        home = f'homeConfigurations."{host["user"]}@{name}".activationPackage.drvPath'
        for output in (system, home):
            print(f"Evaluating {output}", flush=True)
            subprocess.run(["nix", "eval", "--raw", "--no-write-lock-file", f".#" + output],
                           cwd=ROOT, check=True)
            print()


if __name__ == "__main__":
    main()
