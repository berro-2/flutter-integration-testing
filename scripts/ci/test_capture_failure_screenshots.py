"""Tests for live integration-test screenshot requests."""

import json
from pathlib import Path
import tempfile
import unittest

from capture_failure_screenshots import available_path, screenshot_name


class ScreenshotRequestTests(unittest.TestCase):
    def test_reads_screenshot_name_from_flutter_print_event(self):
        event = json.dumps(
            {
                "type": "print",
                "message": "CI_SCREENSHOT_REQUEST:opens-task-details\n",
            }
        )

        self.assertEqual(screenshot_name(event), "opens-task-details")

    def test_ignores_other_machine_events(self):
        self.assertIsNone(screenshot_name(json.dumps({"type": "testDone"})))
        self.assertIsNone(
            screenshot_name(json.dumps({"type": "print", "message": "ordinary log"}))
        )

    def test_does_not_overwrite_an_existing_screenshot(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            output_directory = Path(temporary_directory)
            (output_directory / "failed-test.png").touch()

            self.assertEqual(
                available_path(output_directory, "failed-test").name,
                "failed-test-2.png",
            )


if __name__ == "__main__":
    unittest.main()
