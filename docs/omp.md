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
