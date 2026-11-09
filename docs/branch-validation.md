# Trying the configuration cleanup

Your daily command remains:

```sh
just quick-update neo
```

`quick-update` updates the lockfile once, then builds and switches selected hosts
individually. A host's failed build skips its switch; later selected hosts are
still attempted. It does not run generation cleanup. Run `just clean` separately.

## First run on this branch

For the first trial, validate against the committed lockfile before updating it:

```sh
git status --short
just check
just darwin-build neo
just darwin-switch neo
```

Run `just clean` separately when reclaiming space; it retains current and
last-30-day generations on the Mac and enabled NixOS hosts. `quick-update neo`
updates shared inputs, then builds the selected system and Home Manager outputs
before activating them. Inspect the lock diff even when deploying one host.

## Intentional changes

- Homebrew activation installs declared missing packages but no longer upgrades
  everything or zaps undeclared applications. Use `just brew-update` when you want
  Homebrew upgrades. There is no automatic removal of undeclared apps.
- macOS activation keeps Launch Services quarantine enabled. This does not replace
  the other parts of Gatekeeper or fully manage quarantine metadata on existing apps.
- SSH accepts and records a new host key, but refuses a changed key. Compare the
  initial fingerprint through a trusted channel before the first connection if
  the destination is not already in your known-hosts file.
- `clean` remains explicit and keeps generations newer than 30 days. On macOS it
  uses sudo for the root-owned system profile, then expires Home Manager and Nix
  generations; it also cleans enabled remote NixOS hosts.
- The shared shell only uses the Mac Tailscale application path on Darwin and
  checks that kubectl/direnv exist before loading their shell hooks.

## CI disk capacity

CI still builds the full native system and standalone Home Manager outputs.
On GitHub-hosted macOS runners, it first removes the preinstalled Android
SDK/NDK bundle at `~/Library/Android/sdk`, which these Nix builds do not use.
It preserves Xcode and the selected Apple SDK. Darwin CI limits Nix to one
concurrent build with two cores per build to reduce peak temporary disk use;
Linux and local deployment commands are unchanged. Disk usage is printed
before and after cleanup and at the end of the native job, including failures.

This addresses runner disk pressure seen while building Packer, not a Packer
source defect. A successful hosted run is still required to establish that
the available capacity is sufficient for a cold build.

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
