# Pre-commit Hooks

This repository uses [pre-commit-hooks.nix](https://github.com/cachix/pre-commit-hooks.nix) for automated code quality checks.

## Enabled Hooks (Blocking)

These hooks will block commits if they fail:

- **alejandra**: Nix code formatter
- **check-json**: Validates JSON files
- **check-toml**: Validates TOML files
- **check-yaml**: Validates YAML files

## Available Linters (Non-blocking)

These can be run manually but won't block commits:

- **statix**: Nix linter for best practices (`just lint`)
- **deadnix**: Detects unused Nix code (`just deadnix`)

## Installation

Pre-commit hooks are automatically installed when you enter the development shell:

```bash
nix develop
```

Or manually install them:

```bash
just install-hooks
```

## Usage

### Run all hooks manually

```bash
just run-hooks
```

Or directly:

```bash
nix develop --command pre-commit run --all-files
```

### Format Nix files

```bash
just fmt
```

Or directly:

```bash
nix fmt
```

### Run linters manually

```bash
# Run statix linter
just lint

# Find unused code with deadnix
just deadnix
```

### Check flake

```bash
just check-pre-commit
```

Or directly:

```bash
nix flake check
```

## Automatic Checks

Once installed, pre-commit hooks will run automatically on `git commit`. If any hook fails, the commit will be blocked until you fix the issues.

## Development Shell

The development shell includes all necessary tools:

```bash
nix develop
```

This provides:
- `alejandra` - Nix formatter
- `statix` - Nix linter
- `deadnix` - Dead code detector
- `nil` - Nix LSP
- `pre-commit` - Pre-commit framework

## Bypassing Hooks

If you need to bypass hooks (not recommended):

```bash
git commit --no-verify
```

## Troubleshooting

### Hooks not running

If hooks aren't running on commit, reinstall them:

```bash
just install-hooks
```

### Core.hooksPath conflict

If you see an error about `core.hooksPath`, unset it:

```bash
git config --unset-all core.hooksPath
just install-hooks
```
