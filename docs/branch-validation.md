# Trying the configuration cleanup

Your daily command remains:

```sh
just quick-update neo
```

It updates the lockfile, switches the Mac system and then switches `fs@neo`.
It never contacts `apoc` when `neo` is selected. Errors now return a non-zero exit
status instead of appearing to succeed. An untracked flake source file is reported
with instructions to review and add it; the command does not alter your Git index.

## First run on this branch

For the first trial, validate against the committed lockfile before updating it:

```sh
git status --short
just check
just darwin-build neo
just darwin-switch neo
```

Then resume `just quick-update neo`. Updating inputs on the first run introduces
upstream changes as well as this PR, making any failure harder to attribute.
A build is not a switch: neither the checks nor `darwin-build` activates settings.

## Intentional changes

- Homebrew activation installs declared missing packages but no longer upgrades
  everything or zaps undeclared applications. Use `just brew-update` when you want
  Homebrew upgrades. There is no automatic removal of undeclared apps.
- macOS activation no longer removes quarantine recursively from all applications.
  The existing global `LSQuarantine` preference is retained; this is not a full
  migration of macOS quarantine policy.
- SSH accepts and records a new host key, but refuses a changed key. Compare the
  initial fingerprint through a trusted channel before the first connection if
  the destination is not already in your known-hosts file.
- Cleanup expires generations older than 30 days, rather than removing all old
  generations. `clean` continues to include enabled remote hosts.
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
