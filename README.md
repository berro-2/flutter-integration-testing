# integration_demo_app

A new Flutter project.

## Tests

CI uses Flutter **3.41.4** on Android and iOS. Use the same version locally.

```sh
flutter analyze
flutter test test
flutter test integration_test/task_test.dart -d <device-id>
python -m unittest discover -s scripts/test_reporting -p test_generate_report.py -v
python -m unittest discover -s scripts/ci -p test_retry.py -v
```

The widget tests reuse the 12 device scenarios and check that the driver fails
when an animation never settles. The retry tests require Bash but no simulator.
On Windows, `scripts\test_reporting\run_tests_and_report.bat windows` runs the
desktop integration tests and opens a new HTML report only if generation succeeds.

Reports distinguish passed, failed, skipped, and interrupted tests. A run without
the final machine-reporter event is marked interrupted; a nonzero Flutter exit
code cannot produce a passed report.

iOS makes at most two attempts. Each attempt keeps its JSON, stderr, exit code,
and report in the `ios-test-results` artifact, with simulator logs and a screenshot
captured on failure where available. A second-attempt pass is labeled **PASSED ON
RETRY** in the final report and produces a workflow warning. Android uploads JSON,
stderr, device information, logcat, and a failure screenshot where available in
`android-test-results`.

## Demo login credentials

The login is intentionally a CI demonstration; it does not call an authentication
server. Add these repository secrets under **Settings → Secrets and variables →
Actions**:

- `DEMO_LOGIN_USERNAME`
- `DEMO_LOGIN_PASSWORD`

The mobile workflows pass them to Flutter through a temporary
`--dart-define-from-file` JSON file. CI requires both secrets and deletes that file
after the test run. Pull requests from forks do not receive repository secrets, so
their mobile jobs cannot run this credential test without a trusted rerun.

For a local integration run, the app uses the demo-only values `local-demo-user`
and `local-demo-password`. To exercise custom values locally, create an ignored
JSON file outside the repository:

```json
{
  "DEMO_LOGIN_USERNAME": "your-demo-user",
  "DEMO_LOGIN_PASSWORD": "your-demo-password",
  "REQUIRE_DEMO_CREDENTIALS": true
}
```

Then run:

```sh
flutter test integration_test/task_test.dart -d <device-id> \
  --dart-define-from-file=<path-to-json>
```

These values are compiled into the client application and can be recovered from
the built artifact. Use this only to demonstrate CI secret injection, never as
real application authentication.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
