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
            "sudo": 'exec "$@"',
            "brew": 'exit 0',
            "ssh": 'exit 1',
            "nix": 'printf "%s\\n" "$*" >> "$CALLS"; exit "${NIX_EXIT:-0}"',
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

    def test_daily_mac_path_updates_then_switches_both_outputs(self):
        result = self.run_just("quick-update", "neo")
        self.assertEqual(result.returncode, 0, result.stderr)
        calls = self.log.read_text().splitlines()
        self.assertEqual(calls[0], "flake update")
        self.assertIn("darwin#darwin-rebuild -- switch --flake .#neo", calls[1])
        self.assertIn("home-manager -- switch --flake .#fs@neo", calls[2])
        self.assertEqual(len(calls), 3)

    def test_failed_switch_is_not_success_and_home_is_not_run(self):
        self.env["NIX_EXIT"] = "23"
        result = self.run_just("darwin-switch", "neo")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(len(self.log.read_text().splitlines()), 1)

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
