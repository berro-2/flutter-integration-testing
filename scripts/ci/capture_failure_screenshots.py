"""Capture a device screenshot when a running Flutter test requests one."""

import argparse
import json
from pathlib import Path
import re
import subprocess
import sys


MARKER = "CI_SCREENSHOT_REQUEST:"


def screenshot_name(machine_output_line):
    """Return a safe screenshot name from a Flutter machine print event."""
    try:
        event = json.loads(machine_output_line)
    except json.JSONDecodeError:
        return None

    if not isinstance(event, dict) or event.get("type") != "print":
        return None

    message = str(event.get("message", ""))
    if MARKER not in message:
        return None

    requested_name = message.split(MARKER, 1)[1].splitlines()[0]
    safe_name = re.sub(r"[^a-zA-Z0-9._-]+", "-", requested_name).strip("-.")
    return safe_name[:100] or "failed-test"


def available_path(output_directory, requested_name):
    candidate = output_directory / f"{requested_name}.png"
    suffix = 2
    while candidate.exists():
        candidate = output_directory / f"{requested_name}-{suffix}.png"
        suffix += 1
    return candidate


def capture_screenshot(platform, device_id, output_directory, requested_name):
    output_directory.mkdir(parents=True, exist_ok=True)
    output_file = available_path(output_directory, requested_name)

    if platform == "android":
        with output_file.open("wb") as screenshot:
            result = subprocess.run(
                ["adb", "-s", device_id, "exec-out", "screencap", "-p"],
                stdout=screenshot,
                stderr=subprocess.PIPE,
                check=False,
            )
    else:
        result = subprocess.run(
            ["xcrun", "simctl", "io", device_id, "screenshot", str(output_file)],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )

    if result.returncode == 0 and output_file.exists() and output_file.stat().st_size > 0:
        print(f"Captured active test failure: {output_file}", file=sys.stderr)
        return output_file

    output_file.unlink(missing_ok=True)
    error = result.stderr.decode("utf-8", errors="replace").strip()
    print(
        f"::warning::Could not capture active test failure '{requested_name}': {error}",
        file=sys.stderr,
    )
    return None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("platform", choices=("android", "ios"))
    parser.add_argument("device_id")
    parser.add_argument("output_directory", type=Path)
    args = parser.parse_args()

    for line in sys.stdin:
        requested_name = screenshot_name(line)
        if requested_name:
            capture_screenshot(
                args.platform,
                args.device_id,
                args.output_directory,
                requested_name,
            )


if __name__ == "__main__":
    main()
