"""Deployment contracts exercised with fake tools, without Nix or host access."""
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
JUST = shutil.which("just")


def module(name):
    spec = importlib.util.spec_from_file_location(name, ROOT / "tasks" / f"{name}.py")
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


class SourceTests(unittest.TestCase):
    def test_new_source_is_reported_without_staging_or_missing_path_error(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            subprocess.run(["git", "init", "-q", tmp], check=True)
            (root / "home").mkdir()
            (root / "home" / "new.nix").write_text("{}")
            self.assertEqual(module("check-source").untracked_sources(root), ["home/new.nix"])
            staged = subprocess.check_output(["git", "diff", "--cached", "--name-only"], cwd=root)
            self.assertEqual(staged, b"")


@unittest.skipUnless(JUST, "just is required for deployment contract tests")
class DeploymentTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name) / "repo"
        self.root.mkdir()
        for path in ["justfile", "inventory.json"]:
            shutil.copy(ROOT / path, self.root / path)
        shutil.copytree(ROOT / "tasks", self.root / "tasks")
        subprocess.run(["git", "init", "-q", str(self.root)], check=True)
        subprocess.run(["git", "add", "."], cwd=self.root, check=True)
        self.bin = Path(self.tmp.name) / "bin"
        self.bin.mkdir()
        (self.bin / "just").symlink_to(JUST)
        self.log = Path(self.tmp.name) / "calls"
        self.env = dict(os.environ, PATH=f"{self.bin}:{os.environ['PATH']}", CALLS=str(self.log))
        for tool, body in {
            "doppler": 'shift 2; exec "$@"',
            "sudo": 'IS_SUDO=root; export IS_SUDO; exec "$@"',
            "brew": 'exit 0',
            "ssh": 'printf "ssh %s\\n" "$*" >> "$CALLS"; exit "${SSH_EXIT:-1}"',
            "home-manager": 'printf "home-manager %s\\n" "$*" >> "$CALLS"; exit 0',
            "nix-collect-garbage": 'printf "nix-collect-garbage %s %s\\n" "${IS_SUDO:-user}" "$*" >> "$CALLS"; exit 0',
            "nom": 'printf "nom %s\\n" "$*" >> "$CALLS"; cat',
            "nix": (
                'printf "%s\\n" "$*" >> "$CALLS"\n'
                'if [ -n "${NIX_FAIL_CONTAINS:-}" ]; then\n'
                '  case "$*" in\n'
                '    *"$NIX_FAIL_CONTAINS"*) printf "simulated build failure\\n" >&2; exit "${NIX_FAILURE_CODE:-23}" ;;\n'
                '  esac\n'
                'fi\n'
                'exit "${NIX_EXIT:-0}"'
            ),
        }.items():
            p = self.bin / tool
            p.write_text('#!/bin/sh\n' + body + '\n')
            p.chmod(0o755)

    def run_just(self, *args):
        return subprocess.run([JUST, *args], cwd=self.root, env=self.env,
                              text=True, capture_output=True)

    def test_default_command_only_lists_recipes(self):
        result = self.run_just()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Available recipes", result.stdout)
        self.assertFalse(self.log.exists())

    def test_missing_nom_preflights_before_update_build_or_activation(self):
        (self.bin / "nom").unlink()
        fallback = Path(self.tmp.name) / "required-tools"
        fallback.mkdir()
        # xargs invokes external echo; shell builtins do not satisfy that lookup.
        for tool in ("python3", "git", "hostname", "bash", "sh", "tr", "xargs", "echo", "grep"):
            resolved = shutil.which(tool)
            if resolved:
                (fallback / tool).symlink_to(resolved)
        self.env["PATH"] = f"{self.bin}:{fallback}"

        for command in (
            ("quick-update", "neo"),
            ("darwin-build", "neo"),
            ("darwin-switch", "neo"),
            ("_nixos-home-switch-one", "apoc"),
        ):
            with self.subTest(command=command):
                self.log.unlink(missing_ok=True)
                result = self.run_just(*command)
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertIn("nix develop --command just quick-update neo", result.stderr)
                self.assertFalse(self.log.exists())

    def test_clean_prunes_local_system_user_and_apoc_generations(self):
        self.env["SSH_EXIT"] = "0"
        result = self.run_just("clean")
        self.assertEqual(result.returncode, 0, result.stderr)
        calls = self.log.read_text().splitlines()
        self.assertIn("nix-collect-garbage root --delete-older-than 30d", calls)
        self.assertIn("nix-collect-garbage user --delete-older-than 30d", calls)
        self.assertTrue(any(
            "fs@10.211.55.8" in call and "sudo nix-collect-garbage" in call
            for call in calls
        ))

    def test_quick_update_does_not_clean_or_switch_after_failed_build(self):
        for failed_build in (
            "darwin#darwin-rebuild -- build",
            "home-manager -- build",
        ):
            with self.subTest(failed_build=failed_build):
                self.log.unlink(missing_ok=True)
                self.env["NIX_FAIL_CONTAINS"] = failed_build
                result = self.run_just("quick-update", "neo")
                self.assertNotEqual(result.returncode, 0)
                calls = self.log.read_text().splitlines()
                self.assertFalse(any("nix-collect-garbage" in call for call in calls))
                self.assertFalse(any(call.startswith("ssh ") for call in calls))
                self.assertTrue(any(failed_build in call for call in calls))
                self.assertTrue(any(call.startswith("nom ") for call in calls))
                self.assertIn("simulated build failure", result.stdout)
                self.assertFalse(any("switch --flake .#neo" in call for call in calls))
                self.assertFalse(any("home-manager -- switch" in call for call in calls))

    def test_failed_switch_is_not_success_and_home_is_not_run(self):
        self.env["NIX_EXIT"] = "23"
        result = self.run_just("darwin-switch", "neo")
        self.assertNotEqual(result.returncode, 0)
        calls = self.log.read_text().splitlines()
        self.assertEqual(sum(not call.startswith("nom ") for call in calls), 1)
        self.assertTrue(any(call.startswith("nom ") for call in calls))

    def test_wrong_lane_fails_before_any_build(self):
        result = self.run_just("darwin-build", "apoc")
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.log.exists())

    def test_unknown_host_does_not_update_lock(self):
        self.assertNotEqual(self.run_just("quick-update", "typo").returncode, 0)
        self.assertFalse(self.log.exists())

    def test_offline_remote_is_failure(self):
        self.assertNotEqual(self.run_just("nixos-switch", "apoc").returncode, 0)

    def test_new_source_blocks_update_without_staging(self):
        (self.root / "home").mkdir()
        (self.root / "home" / "new.nix").write_text("{}")
        self.assertNotEqual(self.run_just("quick-update", "neo").returncode, 0)
        self.assertFalse(self.log.exists())
        self.assertEqual(subprocess.check_output(
            ["git", "ls-files", "home/new.nix"], cwd=self.root), b"")

    def test_list_remains_short_and_aliases_remain_callable(self):
        result = self.run_just("--list", "--list-heading", "", "--list-prefix", "")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertLessEqual(len(result.stdout.splitlines()), 16)
        self.assertIn("quick-update", result.stdout)
        self.assertNotIn("darwin-switch-neo", result.stdout)
        self.assertEqual(self.run_just("--show", "darwin-switch-neo").returncode, 0)

    def test_empty_enabled_lane_does_not_run_empty_host(self):
        inventory = json.loads((self.root / "inventory.json").read_text())
        inventory["neo"]["enabled"] = False
        (self.root / "inventory.json").write_text(json.dumps(inventory))
        self.assertEqual(self.run_just("darwin-switch").returncode, 0)
        self.assertFalse(self.log.exists())


if __name__ == "__main__":
    unittest.main()
