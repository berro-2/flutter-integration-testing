"""Check retry orchestration without requiring an Apple simulator."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).with_name('run_ios_tests.sh').resolve().as_posix()
STUBS = r'''
flutter() { echo 'Flutter fixture'; }
xcodebuild() { echo 'Xcode fixture'; }
xcrun() { echo 'Simulator fixture'; }
python3() {
  if [ "$1" = scripts/ci/run_with_timeout.py ]; then
    echo "attempt $attempt"
    echo "diagnostic $attempt" >&2
    if [ "$attempt" = 1 ]; then return "$FIRST_EXIT"; fi
    return "$SECOND_EXIT"
  fi
  echo "report exit $TEST_PROCESS_EXIT_CODE" > "$TEST_REPORTS_DIR/report.txt"
}
source "$RUN_SCRIPT" simulator-fixture
'''


@unittest.skipUnless(shutil.which('bash'), 'Bash is required')
class RetryTests(unittest.TestCase):
    def run_case(self, first, second):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        folder = Path(temp.name)
        env = {**os.environ, 'RUN_SCRIPT': SCRIPT, 'FIRST_EXIT': str(first),
               'SECOND_EXIT': str(second), 'GITHUB_ENV': 'github-env.txt'}
        result = subprocess.run([shutil.which('bash'), '-c', STUBS], cwd=folder, env=env,
                                capture_output=True, text=True)
        return folder, result

    def test_pass_on_retry_preserves_both_attempts(self):
        folder, result = self.run_case(1, 0)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('::warning::iOS passed on retry', result.stdout)
        for attempt, code in [(1, 1), (2, 0)]:
            base = folder / 'ios_diagnostics' / f'attempt-{attempt}'
            self.assertEqual((base / 'exit-code.txt').read_text().strip(), str(code))
            self.assertEqual((base / 'test_results.json').read_text().strip(), f'attempt {attempt}')
            self.assertEqual((base / 'verbose.log').read_text().strip(), f'diagnostic {attempt}')
        self.assertIn('TEST_PASSED_ON_RETRY=true', (folder / 'github-env.txt').read_text())

    def test_second_failure_keeps_nonzero_exit(self):
        folder, result = self.run_case(1, 124)
        self.assertEqual(result.returncode, 124, result.stderr)
        self.assertNotIn('TEST_PASSED_ON_RETRY', (folder / 'github-env.txt').read_text())

    def test_first_pass_does_not_retry(self):
        folder, result = self.run_case(0, 1)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse((folder / 'ios_diagnostics/attempt-2').exists())


if __name__ == '__main__':
    unittest.main()
