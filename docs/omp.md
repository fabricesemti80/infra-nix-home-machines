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

## Provider-specific model setups

`home/modules/ai/omp.nix` generates four complete configurations. Plain `omp`
defaults to **codex**. Use the explicit launchers to select a setup, including
when resuming a conversation whose previous main model used another provider:

```sh
omp-codex
omp-opencode
omp-claude
omp-opencode-mixed
omp-opencode -c
omp-codex -c
```

These are shared-state model setups, not OMP's isolated `--profile` credential
stores. Authentication, sessions, skills, and extensions remain shared. Log in
to OpenCode Go separately using `/login` before relying on the fallback; the
Codex subscription does not fund OpenCode usage. Switching is manual, not an
automatic retry after quota exhaustion. The **claude** setup needs an
Anthropic login (`/login` → Anthropic) before use; **opencode-mixed** needs both
the Codex and Anthropic logins.

| Role | codex (`openai-codex`) | opencode (`opencode-go`) | claude (`anthropic`) | opencode-mixed (`openai-codex` + `anthropic`) |
| --- | --- | --- | --- | --- |
| default | gpt-6.1-sol (low) | gpt-6-luna (medium) | sonnet-5-5 (low) | gpt-6.1-terra (medium) |
| smol, tiny, memory, widget, alternate | gpt-6-luna (low) | gpt-6-luna (low) | haiku-5-5 (low) | gpt-6-luna (low) |
| commit, vision | gpt-6-luna (low) | gpt-6-luna (low) | haiku-5-5 (low) | gpt-6-luna (low) |
| slow | gpt-6.1-sol (high) | gpt-6-luna (high) | opus-5-5 (high) | gpt-6.1-terra (high) |
| advisor | gpt-6.1-sol (high) | gpt-6-luna (low) | sonnet-5-5 (low) | gpt-6-luna (low) |
| plan | gpt-6-astra (high) | glm-5.3 (high) | opus-5-5 (high) | opus-5-5 (high) |
| task | gpt-6-luna (medium) | gpt-6-luna (medium) | sonnet-5-5 (medium) | gpt-6-luna (medium) |

The **opencode-mixed** setup ranks cost above speed. Routine roles use OpenAI's
cheapest model, `gpt-6-luna`; the interactive driver and deep review use
`gpt-6.1-terra`; and only `plan` uses Claude (`opus-5-5`, the cheaper of the two
Opus 5 tiers). Over four chat runs `gpt-6.1-terra:medium` cost about a quarter of
`claude-sonnet-5-5:medium` at similar speed, and `gpt-6.1-sol:low` was both
slower and costlier than terra, so Sol is not used. It runs on the Codex
subscription allowance for OpenAI roles and on Anthropic billing for `plan`.

Astra is reserved for Codex planning. The OpenCode Go setup stays on
`gpt-6-luna` for every routine role and reserves `glm-5.3` for planning.
Measured against the Go catalog with `omp bench`: `gpt-6-luna` starts faster
and decodes faster than the previous `minimax-m3` default while costing a
third as much, and `glm-5.3` is the fastest high-thinking option available.

The codex, opencode, and claude setups run only their own provider's models, so
the OpenCode Go subscription never draws on the Codex allowance and vice versa. The `vision`
role is pinned to `gpt-6-luna` because it is the only Go model in this
allocation that accepts image input — `glm-5.3` and `beam-free` are text-only.

Models whose upstream rejects requests from this account are excluded:
`deepseek-v4-pro` and `deepseek-v4.1-flash` require a different workspace
region, and the free `iceman-contributor-free` and `muse-spark-*-contributor`
models train on request data. `beam-free` is the remaining free model, but it
answers with agent-style narration instead of the requested output, so it is
not used for any role whose text is shown or acted on.
Catalog prices are estimates, not a guarantee of subscription billing or quota consumption.
The OpenCode advisor uses low thinking because `reviewMode = agent-end` runs it
after every turn; explicit reviewer agents retain high thinking through `slow`.
This limits repeated review depth, not a demonstrated TTFT win: the fixed-output
bench measured similar gpt-6-luna TTFT at low and high (748ms vs 711ms p50).
Routine helpers do not use the planning model.

Prewalk remains enabled: post-plan implementation can switch to the selected
setup's `smol` model. Use `--no-prewalk` to retain the main model for harder
implementation work. Named scout/sonic/task/init/review agents route through
these roles using `task.agentModelOverrides`. OMP's source-session model
selection for historical agents, project config, extensions, environment, and
explicit launch overrides can affect routing; provider filters are not a
network sandbox.

Home Manager manages the default `~/.omp/agent/config.yml` and
`~/.omp/agent/model-configs/{codex,opencode,claude,opencode-mixed}.yml` as read-only symlinks.
The launchers use the corresponding Nix-store config and explicitly select its
main model. Each setup enables only its own providers and disables the rest.
The old `sol-default-economical` preset, which mixed providers without a launcher, is removed.
Edit the Nix module and reapply Home Manager to change allocations; do not use
`omp config set` or `/modelpreset switch` to modify these managed files.

The existing symbols, composer, themes, advisor cadence, prewalk, and denied
AutoQA consent are retained. Sessions, provider credentials, extensions, and
existing Pi data are not migrated or deleted.

## Diagram Design skill

`home/modules/ai/diagram-design.nix` installs the complete
[Diagram Design skill](https://github.com/cathrynlavery/diagram-design) for
OMP, Codex (`~/.agents/skills`), Claude Code, and OpenCode on neo's workstation profile.
It is pinned to version 2.6.120; update its revision and hash together.
No marketplace installer or automatic upstream update runs for this skill
during activation.

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
