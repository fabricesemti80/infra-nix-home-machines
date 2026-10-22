# Trying the configuration cleanup

Your daily command remains:

```sh
just quick-update neo
```

Before updating the lockfile, `quick-update` runs the 30-day cleanup locally and
on every enabled NixOS host, including apoc—even when `neo` is the only deployment
target. It then builds and switches only the selected hosts. Cleanup failures stop
the update; build failures prevent switching.

## First run on this branch

For the first trial, validate against the committed lockfile before updating it:

```sh
git status --short
just check
just darwin-build neo
just darwin-switch neo
```

The cleanup retains current and last-30-day generations, then `quick-update neo`
builds the selected system and Home Manager outputs before activating them. Input
updates remain shared across hosts; inspect the lock diff even when deploying one.

## Intentional changes

- Homebrew activation installs declared missing packages but no longer upgrades
  everything or zaps undeclared applications. Use `just brew-update` when you want
  Homebrew upgrades. There is no automatic removal of undeclared apps.
- macOS activation keeps Launch Services quarantine enabled. This does not replace
  the other parts of Gatekeeper or fully manage quarantine metadata on existing apps.
- SSH accepts and records a new host key, but refuses a changed key. Compare the
  initial fingerprint through a trusted channel before the first connection if
  the destination is not already in your known-hosts file.
- Cleanup keeps generations newer than 30 days. On macOS, `clean` uses sudo to
  prune the root-owned system profile, then expires local Home Manager and Nix
  generations; it also cleans enabled remote NixOS hosts.
- The shared shell only uses the Mac Tailscale application path on Darwin and
  checks that kubectl/direnv exist before loading their shell hooks.

## Recovery

Before switching, note the existing generations:

```sh
ls -l /nix/var/nix/profiles/system
home-manager generations
```

If the system activation needs reverting, use the installed tool:

```sh
sudo darwin-rebuild switch --rollback
```

Home Manager is independent: activate the previous generation using the store path
shown by `home-manager generations`, followed by `/activate`. Keep those paths and
avoid cleanup until the new branch has been used successfully.

Changing the Git branch alone does not roll back an already activated system.
