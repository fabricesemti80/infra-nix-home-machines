# Mac Deployment

This page covers macOS hosts managed by nix-darwin and Home Manager.

## Hosts

The active Darwin outputs live in `flake.nix`:

- `neo`

The matching Home Manager outputs are:

- `fs@neo`

## First-Time Setup

Install Nix, clone this repository, and make sure flakes are available.

```sh
git clone <repo-url>
cd nix-hosts
```

The recipes expect Doppler to be available. Log in before switching if the host
does not already have a working Doppler setup.

```sh
doppler me
```

Apply nix-darwin and Home Manager together:

```sh
just darwin-switch neo
```

`darwin-switch` already runs the Home Manager activation. Use `just home-switch neo`
only to retry Home Manager after system activation succeeds.

For another explicitly selected Mac, pass its flake hostname to `darwin-switch`.

## Normal Updates

For the Mac explicitly:

```sh
just quick-update neo
```

Before updating, `quick-update` runs the 30-day cleanup locally and on every
enabled NixOS host, including apoc, then builds and switches the selected Mac.
The local cleanup uses sudo for root-owned Darwin system generations; allow the
sudo prompt if needed.

## Build Without Switching

Use a build recipe when checking a change before applying it:

```sh
just darwin-build
just home-build
```

## Troubleshooting

Show the current hostname, expected flake names, and recent generations:

```sh
just show-config
```

Validate the flake:

```sh
just verify-flake
```

If Home Manager fails after the system switch succeeded, fix the cause and retry
only Home Manager:

```sh
just home-switch neo
```

See [branch validation](branch-validation.md) for changed maintenance behaviour and recovery.
