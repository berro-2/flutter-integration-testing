#!/usr/bin/env bash
set -euo pipefail

device_id="${1:?Simulator device ID is required}"
mkdir -p ios_diagnostics
credentials_file="${RUNNER_TEMP:-.}/demo-login-credentials.json"
trap 'rm -f "$credentials_file"' EXIT
python3 scripts/ci/create_demo_credentials.py "$credentials_file"
flutter --version > ios_diagnostics/flutter-version.txt 2>&1
xcodebuild -version > ios_diagnostics/xcode-version.txt 2>&1

for attempt in 1 2; do
  attempt_dir="ios_diagnostics/attempt-$attempt"
  mkdir -p "$attempt_dir"
  echo "Starting iOS integration-test attempt $attempt of 2."
  xcrun simctl shutdown "$device_id" || true
  # Preserve startup output, including failures before Flutter starts.
  if ! { xcrun simctl boot "$device_id" && xcrun simctl bootstatus "$device_id" -b; } > "$attempt_dir/boot.log" 2>&1; then
    cat "$attempt_dir/boot.log" >&2
    exit 1
  fi

  set +e
  python3 scripts/ci/run_with_timeout.py 420 \
    flutter --verbose test integration_test/task_test.dart \
    -d "$device_id" --machine --dart-define-from-file="$credentials_file" \
    2> >(tee "$attempt_dir/verbose.log" >&2) \
    | tee "$attempt_dir/test_results.json" \
    | python3 scripts/ci/capture_failure_screenshots.py \
        ios "$device_id" "$attempt_dir/failure-screenshots"
  test_exit_code=${PIPESTATUS[0]}
  set -e
  printf '%s\n' "$test_exit_code" > "$attempt_dir/exit-code.txt"
  cat "$attempt_dir/test_results.json"
  cat "$attempt_dir/verbose.log" >&2
  cp "$attempt_dir/test_results.json" ios_test_results.json
  cp "$attempt_dir/verbose.log" ios_test_verbose.log

  TEST_PLATFORM="iOS attempt $attempt" TEST_REPORTS_DIR="$attempt_dir" \
    TEST_PROCESS_EXIT_CODE="$test_exit_code" \
    python3 scripts/test_reporting/generate_report.py
  printf 'TEST_PROCESS_EXIT_CODE=%s\n' "$test_exit_code" >> "$GITHUB_ENV"

  if [ "$test_exit_code" -eq 0 ]; then
    if [ "$attempt" -gt 1 ]; then
      echo '::warning::iOS passed on retry; attempt 1 failed. Inspect ios-test-results.'
      echo 'TEST_PASSED_ON_RETRY=true' >> "$GITHUB_ENV"
    fi
    exit 0
  fi

  # Fallback for crashes and timeouts that bypass the per-test failure wrapper.
  xcrun simctl io "$device_id" screenshot "$attempt_dir/failure.png" || true
  xcrun simctl spawn "$device_id" log show --last 5m --style compact \
    > "$attempt_dir/simulator.log" 2>&1 || true
  if [ "$attempt" -eq 2 ]; then
    exit "$test_exit_code"
  fi
  echo 'Restarting simulator for a diagnostic retry; the failed attempt is retained.'
done
