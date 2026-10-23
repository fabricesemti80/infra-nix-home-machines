"""Regression tests for kubeconfig edits without accessing a live cluster."""
import importlib.util
from pathlib import Path
import tempfile
from unittest.mock import patch
import subprocess
import unittest

spec = importlib.util.spec_from_file_location(
    'helper', Path(__file__).resolve().parents[1] / 'files/lib/kubeconfig_helper.py')
h = importlib.util.module_from_spec(spec)
spec.loader.exec_module(h)


def fixture():
    return {'apiVersion': 'v1', 'kind': 'Config', 'current-context': 'app',
            'clusters': [{'name': n, 'cluster': {'server': 'https://' + n}}
                         for n in ['app', 'infra']],
            'contexts': [{'name': n, 'context': {'cluster': n, 'user': 'shared'}}
                         for n in ['app', 'infra']],
            'users': [{'name': 'shared', 'user': {'token': 'test-placeholder'}}]}


class KubeconfigTests(unittest.TestCase):
    def test_import_renames_all_references_and_preserves_current(self):
        original = fixture()
        result = h.import_context(original, fixture(), 'new', 'infra')
        self.assertEqual(result['current-context'], 'app')
        self.assertEqual(result['contexts'][-1]['context'],
                         {'cluster': 'new', 'user': 'new'})
        self.assertEqual(result['users'][-1]['name'], 'new')
        self.assertEqual(len(original['contexts']), 2)

    def test_import_collision_and_ambiguous_context_fail(self):
        with self.assertRaises(ValueError):
            h.import_context(fixture(), fixture(), 'infra')
        source = fixture()
        source['current-context'] = ''
        with self.assertRaises(ValueError):
            h.import_context(h.empty(), source, 'new')

    def test_delete_preserves_shared_user_and_clears_current(self):
        result, removed = h.delete_cluster(fixture(), 'app')
        self.assertEqual(removed, ['app'])
        self.assertEqual(result['current-context'], '')
        self.assertEqual(result['users'], fixture()['users'])
        result, _ = h.delete_cluster(result, 'infra')
        self.assertEqual(result['users'], [])

    def test_anonymous_import_and_explicit_endpoint(self):
        source = fixture()
        source['contexts'][0]['context'].pop('user')
        result = h.import_context(h.empty(), source, 'new', server='https://api.example')
        self.assertEqual(result['users'], [])
        self.assertEqual(result['current-context'], 'new')
        self.assertEqual(result['clusters'][0]['cluster']['server'], 'https://api.example')

    def test_kubectl_parse_failure_leaves_original_untouched(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'config'
            path.write_bytes(b'invalid yaml')
            with patch.object(h.subprocess, 'run', side_effect=subprocess.CalledProcessError(1, 'kubectl')):
                with self.assertRaises(subprocess.CalledProcessError):
                    h.load(path)
            self.assertEqual(path.read_bytes(), b'invalid yaml')
            self.assertEqual(list(path.parent.glob('config.backup-*')), [])

    def test_atomic_save_private_backup_and_concurrent_edit(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'config'
            path.write_bytes(b'original')
            h.save(path, fixture(), b'original')
            backups = list(path.parent.glob('config.backup-*'))
            self.assertEqual(backups[0].read_bytes(), b'original')
            self.assertEqual(path.stat().st_mode & 0o777, 0o600)
            self.assertEqual(backups[0].stat().st_mode & 0o777, 0o600)
            with self.assertRaises(ValueError):
                h.save(path, h.empty(), b'original')


if __name__ == '__main__':
    unittest.main()
