import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).with_name("create_demo_credentials.py")


class DemoCredentialsTests(unittest.TestCase):
    def test_writes_dart_defines_without_printing_secrets(self):
        with tempfile.TemporaryDirectory() as temp:
            output = Path(temp) / "credentials.json"
            env = {
                **os.environ,
                "DEMO_LOGIN_USERNAME": "ci-demo-user",
                "DEMO_LOGIN_PASSWORD": "ci-demo-password",
            }
            result = subprocess.run(
                [sys.executable, str(SCRIPT), str(output)],
                env=env,
                capture_output=True,
                text=True,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertNotIn("ci-demo-password", result.stdout + result.stderr)
            self.assertEqual(
                json.loads(output.read_text(encoding="utf-8")),
                {
                    "DEMO_LOGIN_USERNAME": "ci-demo-user",
                    "DEMO_LOGIN_PASSWORD": "ci-demo-password",
                    "REQUIRE_DEMO_CREDENTIALS": True,
                },
            )

    def test_fails_when_a_secret_is_missing(self):
        with tempfile.TemporaryDirectory() as temp:
            output = Path(temp) / "credentials.json"
            env = {
                **os.environ,
                "DEMO_LOGIN_USERNAME": "ci-demo-user",
                "DEMO_LOGIN_PASSWORD": "",
            }
            result = subprocess.run(
                [sys.executable, str(SCRIPT), str(output)],
                env=env,
                capture_output=True,
                text=True,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertFalse(output.exists())


if __name__ == "__main__":
    unittest.main()
