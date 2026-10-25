# Oh My Pi (omp)

Website: https://omp.sh/ · Documentation: https://omp.sh/docs

The shared Home Manager AI module installs `pkgs.omp` and configures it through
the dedicated `home/modules/ai/omp.nix` module. The existing nixpkgs lock already
contains omp, so no additional flake input or imperative installer is needed.

After merging, apply your normal update (`just quick-update neo` on the Mac),
open a new terminal, and run:

```sh
omp --version
cd /path/to/project
omp
```

The module declaratively preserves the current `~/.omp/agent/config.yml`
preferences: model roles and the `sol-default-economical` preset, `nerd`
symbols, `pi` composer, `titanium`/`light` themes, advisor review behavior,
prewalk, and denied AutoQA consent. It does not copy TechDufus's personal model
choices, extensions, provider settings, or credentials.

Home Manager manages `~/.omp/agent/config.yml` as a Nix-store-backed symlink.
Edit `home/modules/ai/omp.nix` and reapply Home Manager to change preferences;
direct edits or `omp config set` cannot persist across activation. Use `/login`
for provider authentication. Sessions, auth data, and extensions remain OMP
runtime data and are not managed by this module. Existing Pi sessions,
credentials, extensions and settings are not migrated or deleted.

## Diagram Design skill

`home/modules/ai/diagram-design.nix` installs the complete
[Diagram Design skill](https://github.com/cathrynlavery/diagram-design) for
OMP, Codex (`~/.agents/skills`), Claude Code, and OpenCode on both hosts.
It is pinned to version 2.6.120; update its revision and hash together.
No marketplace installer or automatic upstream update runs during activation.

Restart the agent after switching, then ask it to use `diagram-design` for an
HTML/SVG diagram. This installs the skill and its supporting files, not native
marketplace slash commands. Keep custom profiles in `~/.diagram-design/profiles/`
or select them with a project `.diagram-design` marker; the installed skill is
read-only and should not be edited in place.

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
