import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).with_name('generate_report.py')


class ReportTests(unittest.TestCase):
    def generate(self, events, **extra_env):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        folder = Path(temp.name)
        (folder / 'test_results.json').write_text(
            '\n'.join(json.dumps(event) for event in events), encoding='utf-8')
        env = {**os.environ, 'TEST_REPORTS_DIR': str(folder),
               'GITHUB_STEP_SUMMARY': '', 'TEST_PASSED_ON_RETRY': '',
               'TEST_PROCESS_EXIT_CODE': '0',
               'PYTHONIOENCODING': 'utf-8', **extra_env}
        result = subprocess.run([sys.executable, str(SCRIPT)], env=env,
                                capture_output=True, text=True, encoding='utf-8')
        self.assertEqual(result.returncode, 0, result.stderr)
        report = Path((folder / 'latest_report_name.txt').read_text(encoding='utf-8'))
        return folder, report.read_text(encoding='utf-8'), (folder / 'test_summary.md').read_text(encoding='utf-8')

    def test_mixed_results_including_zero_id_and_interruption(self):
        events = []
        for test_id, name in enumerate(['passed', 'failed', 'skipped', 'interrupted']):
            events.append({'type': 'testStart', 'test': {'id': test_id, 'name': name,
                          'metadata': {'skip': name == 'skipped'}}})
            if name != 'interrupted':
                events.append({'type': 'testDone', 'testID': test_id,
                               'result': 'failure' if name == 'failed' else 'success', 'time': 10})
        _, html, summary = self.generate(events)
        self.assertIn('Overall Result: INTERRUPTED', html)
        self.assertIn('| 4 | 1 | 1 | 1 | 1 |', summary)
        for status in ['PASSED', 'FAILED', 'SKIPPED', 'INTERRUPTED']:
            self.assertIn(status, html)

    def test_retry_and_html_escaping(self):
        _, html, summary = self.generate([
            {'type': 'testStart', 'test': {'id': 0, 'name': '<script> & test'}},
            {'type': 'testDone', 'testID': 0, 'result': 'success'},
            {'type': 'done', 'success': True, 'time': 100},
        ], TEST_PASSED_ON_RETRY='true')
        self.assertIn('PASSED ON RETRY', html)
        self.assertIn('PASSED ON RETRY', summary)
        self.assertIn('&lt;script&gt; &amp; test', html)

    def test_error_before_test_done_is_failed(self):
        _, _, summary = self.generate([
            {'type': 'testStart', 'test': {'id': 1, 'name': 'crashed'}},
            {'type': 'error', 'testID': 1, 'error': 'boom'},
        ])
        self.assertIn('| 1 | 0 | 1 | 0 | 0 |', summary)
        self.assertIn('Overall result: INTERRUPTED', summary)

    def test_failed_generation_removes_stale_pointer(self):
        folder, _, _ = self.generate([{'type': 'done', 'success': False}])
        (folder / 'test_results.json').unlink()
        result = subprocess.run([sys.executable, str(SCRIPT)],
                                env={**os.environ, 'TEST_REPORTS_DIR': str(folder)},
                                capture_output=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((folder / 'latest_report_name.txt').exists())

    def test_process_failure_overrides_success_event(self):
        _, html, _ = self.generate([{'type': 'done', 'success': True}],
                                   TEST_PROCESS_EXIT_CODE='1')
        self.assertIn('Overall Result: FAILED', html)
        self.assertIn('exited with code 1', html)


if __name__ == '__main__':
    unittest.main()
