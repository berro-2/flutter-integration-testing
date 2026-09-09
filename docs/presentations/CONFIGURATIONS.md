# Flutter Integration Testing CI Configuration Guide

This file summarizes how the project configures GitHub Actions secrets, workflow triggers, mobile integration tests, reports, and failure diagnostics.

## Credentials used by this demo

The Flutter demo does not call an authentication API. GitHub Actions supplies two test-only values so the integration test can demonstrate secret injection:

| Secret | Purpose |
| --- | --- |
| `DEMO_LOGIN_USERNAME` | Username accepted by the demo login screen during CI tests. |
| `DEMO_LOGIN_PASSWORD` | Password accepted by the demo login screen during CI tests. |

Create these under **Repository Settings → Secrets and variables → Actions**. Secret names may contain letters, numbers, and underscores; they cannot contain spaces.

The reusable Android and iOS workflows declare both secrets as required. The parent workflow passes the repository secrets to each platform workflow. The test scripts then write them to a temporary JSON file and pass that file to Flutter with `--dart-define-from-file`. The temporary file is deleted when the script exits.

## When GitHub Actions runs

The current parent workflow runs in these situations:

| Trigger | Current configuration | Use |
| --- | --- | --- |
| Push | Pushes to `main` | Validate changes after they reach the main branch. |
| Pull request | Pull requests targeting `main` | Validate proposed changes before merging. |

Other useful trigger configurations that are not currently enabled include:

| Optional trigger | Typical use |
| --- | --- |
| `workflow_dispatch` | Start a workflow manually from GitHub. |
| `schedule` | Run nightly or at another recurring UTC time. |
| `paths` / `paths-ignore` | Run only when relevant files change. |
| Tag filters | Run release checks for tags such as `v*`. |

## CI jobs

| Job | Runner | Main purpose |
| --- | --- | --- |
| Android integration tests | `ubuntu-latest` with an Android emulator | Format, analyze, run unit/widget tests, validate the Android release bundle, and run Flutter integration tests. |
| iOS integration tests | `macos-15` with an iPhone simulator | Format, analyze, validate iOS builds, and run Flutter integration tests with one diagnostic retry. |
| All Mobile Tests Passed | `ubuntu-latest` | Fail the overall workflow unless both platform jobs succeed. |

Both mobile jobs use Flutter `3.41.4`, Python `3.12`, and upload reports even when testing fails.

## Failure diagnostics and artifacts

| Platform | Uploaded artifacts | Screenshot behavior |
| --- | --- | --- |
| Android | HTML report, machine-readable results, verbose Flutter log, emulator logcat, device information, exit code, and the release app bundle after success. | Captures a named image under `android_diagnostics/failure-screenshots/` while each failed test is still active. It also captures `android_diagnostics/failure.png` after the command as a fallback. |
| iOS | HTML report, results and verbose logs for each attempt, boot logs, simulator logs, exit codes, and retry evidence. | Captures a named image under each attempt's `failure-screenshots/` directory while the failed test is still active. It also captures the attempt's `failure.png` as a fallback. |

Each integration scenario uses a shared failure wrapper. When an assertion throws, the wrapper emits a screenshot request and keeps the failed UI active for three seconds while the CI runner captures it. Crashes, process timeouts, and failures before test execution can bypass this wrapper, so the platform scripts retain an end-of-run screenshot as a fallback when the device is available.

## Common CI failure areas

| Stage | Examples | First checks |
| --- | --- | --- |
| Secrets | Missing secret, invalid secret name, empty Dart define | Verify both repository secrets exist and are passed through the parent and reusable workflows. |
| Device startup | Offline Android device, emulator timeout, unavailable iOS runtime | Inspect device, boot, emulator, and simulator diagnostics. |
| Build setup | Flutter version mismatch, Gradle/JDK incompatibility, dependency resolution failure | Confirm the pinned versions and inspect the first setup or build error. |
| Test execution | Widget not found, widget cannot be tapped, timeout, state leaking between tests | Check the screenshot and verbose log, then identify the first failed test and its visible UI state. |
| Reporting | Missing or invalid machine-readable JSON, interrupted process, stale output | Check the recorded process exit code and confirm the report input was produced during the current run. |

Start troubleshooting at the first failed stage: setup, build, device startup, test execution, or reporting. Later errors are often consequences of that first failure.
