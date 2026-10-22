# Oh My Pi (omp)

Website: https://omp.sh/ · Documentation: https://omp.sh/docs

The shared Home Manager AI module installs `pkgs.omp` instead of
`pkgs.pi-coding-agent` on macOS and Linux. The existing nixpkgs lock already
contains omp, so no additional flake input or imperative installer is needed.

After merging, apply your normal update (`just quick-update neo` on the Mac),
open a new terminal, and run:

```sh
omp --version
cd /path/to/project
omp
```

Use `/login` to connect your provider, then `/model` to select a model and
configure roles. See https://omp.sh/docs/roles for role assignments and
https://omp.sh/docs/custom-models for LM Studio and other local endpoints.

This changes the installed CLI from `pi` to `omp`. Existing Pi sessions,
credentials, extensions and settings are not migrated or deleted. Configure
omp separately; its default user configuration directory is `~/.omp/agent/`.
Model and provider choices remain user-managed.

## Herdr detection

The Darwin-only `omp-herdr-fix` overlay preserves `argv[0] = omp` when its Nix
launcher execs Bun. Without it, Herdr sees `bun …/packages/coding-agent/dist/cli.js`,
which does not match its OMP process detection. Herdr is configured only on macOS;
Linux keeps the upstream `pkgs.omp` derivation and its binary-cache eligibility.

Apply launcher changes without updating flake inputs:

```sh
just home-switch neo
```

Install the [Herdr OMP integration](https://herdr.dev/docs/integrations/#omp)
if needed, then restart existing omp processes (resume with `omp -c`):

```sh
herdr integration install omp
herdr integration status
omp -c
```

From another terminal, `herdr agent list` should show `agent: "omp"` and its
lifecycle state. `herdr pane process-info --pane <pane-id>` should show
`argv0: "omp"`; the underlying executable name remains `bun`.
