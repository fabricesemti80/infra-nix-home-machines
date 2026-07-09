# Just Recipes

The `justfile` is the main operator interface for this repository.

List everything available:

```sh
just --list
```

Most recipes wrap their command with `doppler run --` so secrets and local
environment values are available consistently.

## Daily Commands

`quick-update`
: Updates the flake lock, then switches every enabled deployment lane:
`darwin-switch`, `nixos-switch`, and `vm-switch`.

Aggregate recipes are best-effort per host. If a host is offline, the aggregate
command prints a skip message for that host and continues with the remaining
lanes. Explicit host commands such as `just nixos-switch apoc` still fail when
that host cannot be reached.

Long-running recipes print colored section banners so the `quick-update` output
is easier to scan. Flake/update steps are yellow, Darwin is cyan, Home Manager
is blue, physical NixOS hosts are green, and VMs are magenta.

Current enabled targets:

| Lane | Default Targets | What It Switches |
|------|-----------------|------------------|
| `darwin-*` | `neo` | nix-darwin plus `fs@neo` Home Manager |
| `nixos-*` | `apoc` | NixOS host plus `fs@apoc` Home Manager over SSH |

`home-switch`
: Keeps the old local muscle memory. It switches Home Manager for the current
hostname, or for an explicit host with `just home-switch <hostname>`.

`quick-update-lane <lane>`
: Updates the flake lock, then switches one lane. Valid lanes are `darwin` and
`nixos`.

## Darwin Hosts

Darwin recipes target all enabled Macs by default. Pass a hostname to target one
Mac.

```sh
just darwin-switch
just darwin-switch neo
just darwin-build
just darwin-build neo
just darwin-home-switch
just darwin-home-switch neo
just darwin-home-build
just darwin-home-build neo
```

`darwin-switch`
: Applies nix-darwin, then applies the matching Home Manager output.

`darwin-build`
: Builds nix-darwin, then builds the matching Home Manager output.

`darwin-home-switch` and `darwin-home-build`
: Run only the Home Manager half of the Darwin lane.

Compatibility aliases remain for older habits:

```sh
just darwin-switch-neo
just home-switch-neo
```

## Physical NixOS Hosts

Physical NixOS recipes target all enabled physical hosts by default. Pass a
hostname to target one host.

```sh
just nixos-build
just nixos-build apoc
just nixos-switch
just nixos-switch apoc
just nixos-home-build
just nixos-home-build apoc
just nixos-home-switch
just nixos-home-switch apoc
```

`nixos-build`
: Builds the physical host remotely with `nixos-rebuild build`, then builds the
matching Home Manager activation package.

`nixos-switch`
: Switches the physical host remotely with `nixos-rebuild switch`, tries to
authenticate Tailscale with `TAILSCALE_AUTH_KEY` if that secret is available,
then switches the matching Home Manager profile.

`nixos-home-build`
: Builds only the physical host's Home Manager activation package. Linux Home
Manager outputs are built on the physical host itself, so this works when
driven from an Apple Silicon Mac.

`nixos-home-switch`
: Archives the current flake to the physical host, builds the Home Manager
activation package there, then runs the activation script as `fs`.

Physical NixOS recipes check SSH reachability before starting the remote build
or switch.

Physical host SSH targets are resolved in private recipes in the `justfile`. At
the moment, `apoc` resolves to `fs@10.211.55.8` for both system operations and
Home Manager activation.

## Flake Management

`update`
: Runs `nix flake update`.

`verify-flake`
: Runs `nix flake check`.

`repl`
: Opens a Nix REPL for the current flake.

## Terraform

Terraform recipes run in the `infra/` directory.

```sh
just tf init
just tf plan
just tf apply
just tf output ssh_targets
```

Convenience wrappers:

```sh
just tf-init
just tf-upgrade
just tf-validate
```

`just tf` runs Terraform through `doppler run --name-transformer tf-var --`, so
uppercase Doppler keys such as `PROXMOX_TOKEN_SECRET` and `CLOUDFLARE_API_TOKEN`
are exposed as Terraform's expected `TF_VAR_...` environment variables.

## VM Deployment

`vm-build`
: Builds the NixOS Proxmox cloud image into `result-cloud/`. On Darwin, this
runs the Linux build inside Docker.

`vm-plan`
: Builds the cloud image, then runs Terraform plan.

`vm-apply`
: Builds the cloud image, uploads/imports it through Terraform, and applies VM
infrastructure changes.

(VM deployment recipes removed — no VM hosts remain in the config.)

## Quality And Maintenance

```sh
just fmt
just lint
just lint-fix
just deadnix
just deadnix-fix
just install-hooks
just run-hooks
just check-pre-commit
just clean
```

Use `fmt` before commits. Use `run-hooks` or `check-pre-commit` when changing
flake structure, host modules, or docs that should pass repository checks.
