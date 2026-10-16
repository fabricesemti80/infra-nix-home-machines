"""Safe import contracts and ciphertext guards; no real credentials are used."""
import importlib.util
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


def load(name):
    spec = importlib.util.spec_from_file_location(name, ROOT / "tools" / f"{name}.py")
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


class ImportTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.ssh = Path(self.tmp.name) / ".ssh"
        self.ssh.mkdir()
        self.Importer = load("import-ssh-config").Importer

    def test_includes_keep_their_scope_and_identity_files_are_not_read(self):
        (self.ssh / "config").write_text('Host office\n  Include conf.d/*.conf\nHost *\n  ForwardAgent no\n')
        (self.ssh / "conf.d").mkdir()
        (self.ssh / "conf.d/a.conf").write_text('  IdentityFile ~/.ssh/missing-private-key\n')
        importer = self.Importer(self.ssh)
        manifest = importer.snapshot()
        self.assertIn('Include "~/.ssh/config.d/nix-imported/include-001.conf"', importer.files["config"])
        self.assertIn("Host *\n", importer.files["config"])
        self.assertEqual(manifest["identity_files_referenced_not_read"], ["~/.ssh/missing-private-key"])
        self.assertEqual((self.ssh / "config").read_text().count("nix-imported"), 0)

    @unittest.skipUnless(shutil.which("ssh"), "OpenSSH needed for effective-config comparison")
    def test_effective_openssh_config_is_preserved(self):
        included = self.ssh / "included.conf"
        included.write_text('Host office\n IdentityFile ~/.ssh/missing\nHost other\n User alternate\n')
        config = self.ssh / "config"
        config.write_text(f'Host office\n HostName office.example.invalid\n Include "{included}"\nHost *\n User fallback\n')
        snapshot = Path(self.tmp.name) / "snapshot"
        snapshot.mkdir()
        importer = self.Importer(self.ssh, managed_prefix=str(snapshot))
        importer.snapshot()
        for name, content in importer.files.items():
            (snapshot / name).write_text(content)
        for alias in ("office", "other"):
            before = subprocess.check_output(["ssh", "-G", "-F", str(config), alias], stderr=subprocess.DEVNULL)
            after = subprocess.check_output(["ssh", "-G", "-F", str(snapshot / "config"), alias], stderr=subprocess.DEVNULL)
            self.assertEqual(before, after)

    def test_recursive_include_is_rejected(self):
        (self.ssh / "config").write_text('Include config\n')
        with self.assertRaisesRegex(ValueError, "Recursive"):
            self.Importer(self.ssh).snapshot()

    def test_external_and_unmatched_includes_are_reported(self):
        (self.ssh / "config").write_text('Include /etc/ssh/managed.conf absent/*.conf\n')
        importer = self.Importer(self.ssh)
        self.assertEqual(importer.snapshot()["external_includes"], ["/etc/ssh/managed.conf", "absent/*.conf"])
        self.assertIn('/etc/ssh/managed.conf', importer.files['config'])

    def test_private_material_is_rejected(self):
        (self.ssh / "config").write_text('-----BEGIN OPENSSH PRIVATE KEY-----\nnot-a-real-key\n')
        with self.assertRaisesRegex(ValueError, "private-key"):
            self.Importer(self.ssh).snapshot()

    def test_dry_run_writes_nothing(self):
        (self.ssh / "config").write_text('Host test\n HostName 127.0.0.1\n')
        result = subprocess.run(['python3', str(ROOT / 'tools/import-ssh-config.py'),
                                 '--label', 'dry-run-test', '--ssh-dir', str(self.ssh)],
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse((ROOT / 'files/ssh/imported/dry-run-test').exists())


class CiphertextTests(unittest.TestCase):
    def test_encrypted_payload_passes_and_plaintext_fails_without_echoing_value(self):
        guard = load('check-secrets')
        import yaml
        with tempfile.TemporaryDirectory() as tmp:
            file = Path(tmp) / 'fixture.yaml'
            body = {'key': 'ENC[AES256_GCM,data:fake,tag:fake,type:str]',
                    'sops': {'age': [{'recipient': 'age1fixture'}], 'mac': 'encrypted-mac'}}
            file.write_text(yaml.safe_dump(body))
            guard.validate(file)
            body['key'] = 'private-fixture-never-print'
            file.write_text(yaml.safe_dump(body))
            with self.assertRaisesRegex(ValueError, 'ciphertext') as result:
                guard.validate(file)
            self.assertNotIn(body['key'], str(result.exception))


@unittest.skipUnless(shutil.which('sops') and shutil.which('age-keygen'), 'sops and age required')
class EncryptionTests(unittest.TestCase):
    def test_helper_encrypts_via_stdin_and_ciphertext_decrypts(self):
        # Isolate the helper's entire repository root, including recipient policy.
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / 'tools').mkdir()
            (root / 'secrets').mkdir()
            helper = root / 'tools/encrypt-ssh-keys.py'
            shutil.copy(ROOT / 'tools/encrypt-ssh-keys.py', helper)
            shutil.copy(ROOT / 'tools/check-secrets.py', root / 'tools/check-secrets.py')
            age_key = root / 'fixture.agekey'
            subprocess.run(['age-keygen', '-o', str(age_key)], check=True, capture_output=True)
            recipient = subprocess.check_output(['age-keygen', '-y', str(age_key)], text=True).strip()
            (root / '.sops.yaml').write_text(f'creation_rules:\n  - path_regex: secrets/test\\.yaml$\n    age: {recipient}\n')
            identity = root / 'identity'
            fixture = '-----BEGIN OPENSSH PRIVATE KEY-----\nnot-a-real-ssh-key\n-----END OPENSSH PRIVATE KEY-----\n'
            identity.write_text(fixture)
            result = subprocess.run(['python3', str(helper), 'secrets/test.yaml', '--key', f'test={identity}'],
                                    cwd=root, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertNotIn('not-a-real-ssh-key', result.stdout + result.stderr)
            ciphertext = (root / 'secrets/test.yaml').read_text()
            self.assertNotIn('not-a-real-ssh-key', ciphertext)
            import os
            env = dict(os.environ, SOPS_AGE_KEY_FILE=str(age_key))
            result = subprocess.check_output(['sops', '--decrypt', '--output-type', 'json', 'secrets/test.yaml'],
                                              cwd=root, env=env, text=True)
            self.assertEqual(json.loads(result)['test'], fixture)
            again = subprocess.run(['python3', str(helper), 'secrets/test.yaml', '--key', f'test={identity}'],
                                   cwd=root, capture_output=True)
            self.assertNotEqual(again.returncode, 0)
            self.assertEqual((root / 'secrets/test.yaml').read_text(), ciphertext)
            # A recipient policy may deliberately exempt a field from encryption.
            # The helper must refuse to write even if another field was encrypted.
            (root / '.sops.yaml').write_text(
                f'creation_rules:\n  - path_regex: secrets/.*\\.yaml$\n    age: {recipient}\n    unencrypted_suffix: _unencrypted\n')
            partial = subprocess.run(['python3', str(helper), 'secrets/partial.yaml',
                                      '--key', f'visible_unencrypted={identity}',
                                      '--key', f'safe={identity}'], cwd=root, capture_output=True)
            self.assertNotEqual(partial.returncode, 0)
            self.assertFalse((root / 'secrets/partial.yaml').exists())
            self.assertNotIn(b'not-a-real-ssh-key', partial.stdout + partial.stderr)



if __name__ == '__main__':
    unittest.main()
