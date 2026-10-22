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

`quick-update` updates flake inputs, builds and switches the selected Mac after
successful builds. Generation cleanup remains separate: run `just clean` when
you want to reclaim space. It retains current and 30-day generations and includes
enabled NixOS hosts such as apoc.

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
