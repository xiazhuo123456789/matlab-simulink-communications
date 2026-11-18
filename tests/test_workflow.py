import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('workflow', Path(__file__).parents[1] / 'scripts/workflow.py')
w = importlib.util.module_from_spec(spec)
spec.loader.exec_module(w)


class WorkflowTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='matlab-agent-')
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name) / "test's project"
        self.root.mkdir()
        (self.root / 'run.m').write_text('disp(1);')
        self.cfg = {'schemaVersion': 1, 'entryPoint': 'run.m',
                    'outputs': {'directory': 'out', 'requiredFiles': ['figure.png']}}
        self.path = self.root / 'config.json'
        self.write_config()

    def write_config(self):
        self.path.write_text(json.dumps(self.cfg), encoding='utf-8')

    def test_config_relative_to_file_not_cwd(self):
        _, _, root, entry, out = w.read_config(self.path)
        self.assertEqual(root, self.root)
        self.assertEqual(entry, self.root / 'run.m')
        self.assertEqual(out, self.root / 'out')

    def test_inspection_has_no_side_effects(self):
        before = set(self.root.rglob('*'))
        self.assertIn('run.m', w.discover(self.root)['matlabFiles'])
        self.assertEqual(before, set(self.root.rglob('*')))

    def test_matlab_string_escapes_apostrophe(self):
        result = w.execute(self.path, dry_run=True)
        self.assertIn("test''s project", result['command'][2])
        self.assertFalse((self.root / 'out').exists())

    def test_manifest_traversal_rejected(self):
        self.cfg['outputs']['requiredFiles'] = ['../run.m']
        self.write_config()
        with self.assertRaises(ValueError):
            w.read_config(self.path)

    def test_entrypoint_traversal_rejected(self):
        self.cfg['entryPoint'] = '../outside.m'
        (self.root.parent / 'outside.m').write_text('disp(1);')
        self.write_config()
        with self.assertRaises(ValueError):
            w.read_config(self.path)

    def test_zero_length_and_missing_outputs_fail(self):
        (self.root / 'empty.png').touch()
        result = w.verify(self.root, ['empty.png', 'missing.png'])
        self.assertFalse(result['ok'])
        self.assertEqual(len(result['missing']), 2)

    def test_verify_rejects_symlink_escape(self):
        external = self.root.parent / 'external.png'
        external.write_bytes(b'outside')
        try:
            (self.root / 'link.png').symlink_to(external)
        except (OSError, NotImplementedError):
            self.skipTest('Symlink creation is unavailable')
        with self.assertRaises(ValueError):
            w.verify(self.root, ['link.png'])

    def test_metrics_denominator_mismatch_rejected(self):
        metrics = {'bits': 8000, 'bitErrors': 14, 'BER': .5, 'symbols': 2000,
                   'symbolErrors': 14, 'SER': .007, 'noiselessBitErrors': 0}
        (self.root / 'metrics.json').write_text(json.dumps(metrics))
        self.assertFalse(w.verify(self.root, ['metrics.json'], 'metrics.json')['ok'])
        metrics['BER'] = 14/8000
        (self.root / 'metrics.json').write_text(json.dumps(metrics))
        self.assertTrue(w.verify(self.root, ['metrics.json'], 'metrics.json')['ok'])

    def test_matlab_error_propagates(self):
        with patch.object(w.subprocess, 'run', return_value=subprocess.CompletedProcess([], 9)):
            with self.assertRaises(RuntimeError):
                w.execute(self.path, matlab='mock-matlab')
        self.assertTrue((self.root / 'out/matlab.log').exists())

    def test_existing_outputs_never_reused(self):
        (self.root / 'out').mkdir()
        with patch.object(w.subprocess, 'run') as process:
            with self.assertRaises(FileExistsError):
                w.execute(self.path, matlab='mock-matlab')
            process.assert_not_called()

    def test_success_requires_fresh_outputs_and_passes_config(self):
        def simulate(args, **kwargs):
            self.assertEqual(kwargs['env']['MSC_CONFIG_FILE'], str(self.path))
            self.assertNotIn('shell', kwargs)
            Path(kwargs['env']['MSC_OUTPUT_DIR'], 'figure.png').write_bytes(b'fixture')
            return subprocess.CompletedProcess(args, 0)
        with patch.object(w.subprocess, 'run', side_effect=simulate):
            self.assertTrue(w.execute(self.path, matlab='mock-matlab')['ok'])

    def test_timeout_preserves_log(self):
        with patch.object(w.subprocess, 'run', side_effect=subprocess.TimeoutExpired('mock', 1)):
            with self.assertRaises(subprocess.TimeoutExpired):
                w.execute(self.path, matlab='mock-matlab')
        self.assertTrue((self.root / 'out/matlab.log').exists())


if __name__ == '__main__':
    unittest.main()
