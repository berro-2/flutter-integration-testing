# From manual testing to automated Flutter testing

This guide assumes an existing Flutter mobile app that already works and has been tested manually. It takes you from selecting the first scenario to running tests on Android and iOS in GitHub Actions, publishing results, and collecting failure screenshots.

Examples use a login flow. Replace the package name, widget keys, environment configuration, and expected screens with those in your app. This is an implementation guide; it does not mean these steps have been executed against another app.

## 1. Record the working baseline

Create a branch for the testing changes. Record the commit, Flutter version, supported platforms, build flavors, backend environment, and commands currently used to run the app.

From the app’s root folder, run:

```sh
flutter --version
flutter doctor -v
flutter pub get
flutter analyze
flutter devices
```

Run the app on a target device and confirm the existing manual smoke test still works:

```sh
flutter run -d <device-id>
```

If the app requires a flavor or configuration file, include the same arguments in subsequent test commands. Resolve setup failures before adding automation. Keep any existing tests and record their baseline results.

Use the app’s known-compatible Flutter version locally and in CI. This demo pins `3.41.4`; another app should use its own validated version.

## 2. Turn the manual checklist into explicit test cases

Create `docs/testing/test-plan.md`. For each case, write the starting state, exact actions, expected results, required data, and cleanup.

| ID | Starting state | Actions | Expected result | Cleanup |
| --- | --- | --- | --- | --- |
| LOGIN-01 | Logged out; valid test account | Enter credentials; submit | Dashboard visible; login screen gone | Sign out/reset session |
| LOGIN-02 | Logged out | Submit invalid credentials | Error visible; dashboard inaccessible | Reset session |
| TASK-01 | Logged in; isolated test data | Create task with unique title | Task appears and count increases | Delete created task |
| TASK-02 | Logged in | Submit empty title | Validation message; no new task | Close form |

Start with a small smoke suite covering the most important user journey. Add validation, permission, error, and edge cases after the first flow works. Every automated case needs an assertion: tapping through screens alone does not prove success.

## 3. Choose the right test level

| Level | Use it for | Where it runs |
| --- | --- | --- |
| Unit | Calculations, parsing, validation, business rules | Dart/Flutter test process |
| Widget | Screen rendering, form errors, component interactions with controlled dependencies | Flutter test environment |
| Integration | Full app journeys and platform/backend interactions | Device, emulator, or simulator |

Put fast tests under `test/` and device scenarios under `integration_test/`. Keep manual exploratory, usability, and visual checks alongside automation. Flutter describes these levels in its [testing overview](https://docs.flutter.dev/testing/overview).

## 4. Prepare a repeatable test environment

For a real app, provision a staging/test backend and dedicated test accounts. Decide how each test will create and delete its own data. Avoid sharing mutable records across Android and iOS jobs running at the same time.

Reset authentication, local storage, caches, and dependency state before each independent test. If the app uses a database or remote service, rebuilding the Flutter widget tree does not reset that data. Provide an explicit test setup/cleanup mechanism and use unique record names where necessary.

Keep real authentication in the integration path if authentication is what you are testing. The demo repository compares locally compiled credentials; do not copy that comparison into a production app as an authentication implementation.

Define the behavior for permissions, onboarding, network errors, and loading states so the test can start predictably.

## 5. Add the Flutter testing dependencies

Merge these entries into the existing `pubspec.yaml`; do not create duplicate `dev_dependencies` sections:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
```

Run `flutter pub get`. Commit the updated manifest and app lockfile. The official [integration test setup](https://docs.flutter.dev/testing/integration-tests) explains the SDK packages and device execution.

## 6. Add stable widget identifiers

Add keys to important inputs, buttons, screens, and result widgets in the existing app:

```dart
TextFormField(
  key: const Key('login_username_input'),
  controller: usernameController,
)

ElevatedButton(
  key: const Key('login_submit_button'),
  onPressed: submitLogin,
  child: const Text('Sign in'),
)
```

Also key the password input and dashboard screen. Use unique, meaningful keys. For dynamic records, prefer stable record IDs over list positions when ordering may change. Keys help tests locate widgets without depending on coordinates or translated labels.

## 7. Write one complete integration test

Create `integration_test/app_test.dart`. The following template assumes the app starts on login with a cleared session and exposes the named keys:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:your_app/main.dart' as app;

Future<void> waitFor(WidgetTester tester, Finder target) async {
  final deadline = DateTime.now().add(const Duration(seconds: 15));
  while (target.evaluate().isEmpty && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(target, findsOneWidget);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('valid login opens the dashboard', (tester) async {
    const username = String.fromEnvironment('TEST_USERNAME');
    const password = String.fromEnvironment('TEST_PASSWORD');
    expect(username, isNotEmpty, reason: 'Configure TEST_USERNAME');
    expect(password, isNotEmpty, reason: 'Configure TEST_PASSWORD');

    // Run your app-specific storage/session reset before startup here.
    app.main();
    await waitFor(tester, find.byKey(const Key('login_username_input')));
    await tester.enterText(
      find.byKey(const Key('login_username_input')), username,
    );
    await tester.enterText(
      find.byKey(const Key('login_password_input')), password,
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle(timeout: const Duration(seconds: 5));
    final submit = find.byKey(const Key('login_submit_button'));
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle(timeout: const Duration(seconds: 5));
    expect(submit.hitTestable(), findsOneWidget);
    await tester.tap(submit.hitTestable());
    await waitFor(tester, find.byKey(const Key('dashboard_screen')));
    expect(find.byKey(const Key('login_username_input')), findsNothing);
  });
}
```

Replace `your_app` with the `name` in your app’s `pubspec.yaml`. Adapt startup if it requires awaited initialization. Implement the reset mentioned in the comment before extending to multiple cases.

Wait for meaningful UI states with a timeout. `pumpAndSettle` waits for scheduled frames to stop; continuous animations can make it time out, and it does not guarantee that a network request finished. Use condition-based waits for asynchronous results. See Flutter’s [integration testing example](https://docs.flutter.dev/cookbook/testing/integration/introduction).

## 8. Supply local test configuration

Create a JSON file outside the repository with the dedicated test account:

```json
{
  "TEST_USERNAME": "dedicated-test-user",
  "TEST_PASSWORD": "dedicated-test-password"
}
```

Add any app-specific API URL or flavor configuration using the names your app actually reads. Dart defines are build-time configuration and can be recovered from built artifacts; use test-only credentials and keep this file out of Git.

Start an Android emulator or connect a device, then run:

```sh
flutter devices
flutter test integration_test/app_test.dart -d <device-id> --dart-define-from-file=<path-to-json>
```

For local iOS execution, use a Mac with Xcode and an available iOS simulator. Windows cannot host an iOS simulator.

Confirm that changing an expected value causes the test to fail, then restore it. This verifies that the assertions are actually checking the intended result.

## 9. Expand and organize the suite

After the first test is stable, extract shared interactions and add the selected manual cases:

```text
integration_test/
  app_test.dart
  support/
    app_test_driver.dart
  suites/
    login_suite.dart
    task_suite.dart
test/
  validation_test.dart
  login_widget_test.dart
```

Keep assertions readable in each scenario. A helper should fail when a widget is absent or untappable; it must not swallow the failure. Every test should work independently, including when run alone. Exercise both Android and iOS before declaring a cross-platform journey covered.

## 10. Add machine-readable results and reporting

Flutter’s `--machine` option produces events for test starts, completions, errors, and the final run result. Capture stdout, stderr, and the process exit code separately.

This Bash example is intended for Linux/macOS CI:

```bash
mkdir -p test_reports
set +e
flutter test integration_test/app_test.dart -d "$DEVICE_ID" \
  --machine --dart-define-from-file="$CREDENTIALS_FILE" \
  > test_reports/test_results.json 2> test_reports/flutter-stderr.log
test_exit_code=$?
set -e
printf '%s\n' "$test_exit_code" > test_reports/exit-code.txt
export TEST_PROCESS_EXIT_CODE="$test_exit_code"
python3 scripts/test_reporting/generate_report.py
exit "$test_exit_code"
```

For a new app, copy `scripts/test_reporting/generate_report.py` and `test_generate_report.py` from this demo into the same relative location. The generator is custom project code, not a built-in Flutter HTML reporter. It reads `test_reports/test_results.json` by default and produces HTML and Markdown.

Validate it with:

```sh
python -m unittest discover -s scripts/test_reporting -p test_generate_report.py -v
```

On Windows, the demo’s `scripts/test_reporting/run_tests_and_report.bat` is a starting point. Adapt its target file and configuration arguments before reuse; its existing target is `integration_test/task_test.dart`.

## 11. Create the GitHub workflow files

In the existing app’s repository, create `.github/workflows/`. This demo provides a complete reusable starting point:

| Copy from this demo | Purpose |
| --- | --- |
| `.github/workflows/flutter-ci.yml` | Triggers Android/iOS and checks their combined result |
| `.github/workflows/android-tests.yml` | Linux runner, Android emulator, checks, reports, artifacts |
| `.github/workflows/ios-tests.yml` | macOS runner, iOS simulator, checks, reports, artifacts |
| `scripts/ci/run_android_tests.sh` | Android test execution, exit code, diagnostics |
| `scripts/ci/run_ios_tests.sh` | iOS execution, retry evidence, diagnostics |
| `scripts/ci/run_with_timeout.py` | Bounds the iOS command and terminates timed-out processes |
| `scripts/ci/create_demo_credentials.py` | Temporary configuration file pattern; adapt for real test accounts |
| `scripts/ci/test_*.py` | Regression checks for the copied CI helpers; adapt with the scripts |

Before using the copied files, make these changes together:

1. Replace `integration_test/task_test.dart` with your test entry point.
2. Set the Flutter version to the app’s validated version.
3. Match Java/Gradle, Android SDK, Xcode, and iOS runtime requirements to the app and runner.
4. Add required flavor, target, and environment arguments to both build and test commands.
5. Replace demo secret names and temporary JSON keys with `TEST_USERNAME`/`TEST_PASSWORD`, matching the example test. Update the parent workflow, reusable workflow declarations, environment mappings, credential script, and its tests together.
6. Remove the demo-only `REQUIRE_DEMO_CREDENTIALS` convention unless the new app explicitly implements it.
7. Update build artifact paths if flavors change the output location.
8. Confirm the Android device ID matches the emulator and the iOS runtime exists on the selected macOS runner.
9. Review all retained checks and timeouts for the new app.

Use the actual YAML files under `.github/workflows/`, not the historical `docs/ci/workflow-reference.txt`. The workflow folder is GitHub’s standard location for [workflow definitions](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax).

## 12. Configure GitHub secrets and triggers

In the target repository, open **Settings → Secrets and variables → Actions → New repository secret**. Add the test username and password using the exact names referenced by the adapted workflows.

Pass secrets to a step through `env`, then have the credential script write a temporary JSON file, pass it via `--dart-define-from-file`, and delete it when the script exits. Do not print the file contents. Fork pull requests do not normally receive repository secrets; decide whether they run a secret-free suite or require an approved trusted workflow. See [GitHub’s secrets documentation](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets).

For an easy first run, add manual dispatch to the parent workflow alongside push and pull-request triggers:

```yaml
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch:
```

Use the actual default branch name. The manual Run workflow button requires the workflow with `workflow_dispatch` to exist on the default branch. Before that, open a pull request to exercise the PR trigger.

## 13. Publish the summary and downloadable reports

The workflow runs `python3 scripts/test_reporting/generate_report.py`. The generator writes Markdown to the file specified by GitHub’s automatic `GITHUB_STEP_SUMMARY` environment variable. GitHub renders it on the run’s Summary page. You do not create this variable as a secret.

A minimal demonstration is:

```yaml
- name: Write summary
  run: echo "## Integration test results" >> "$GITHUB_STEP_SUMMARY"
```

Upload the HTML report, raw JSON, stderr, and diagnostics as artifacts. Keep the copied `if: always()` conditions so uploads are attempted even after a failing test. Preserve the nonzero test exit code: a successfully generated report must not turn failing tests into a successful job. GitHub documents [job summaries](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands#adding-a-job-summary).

## 14. Capture failure screenshots

The copied scripts already attempt capture after a failing test command:

```bash
# Android
adb -s "$DEVICE_ID" exec-out screencap -p > failure.png

# iOS
xcrun simctl io "$DEVICE_ID" screenshot failure.png
```

Keep each image in the directory uploaded by the workflow. In this demo, Android uses `android_diagnostics/failure.png`; iOS uses `ios_diagnostics/attempt-N/failure.png`.

These are post-command device screenshots, not one image per failed assertion. If the team needs the exact failing UI state, add capture at the test failure boundary and verify that the framework saves and exports the image before teardown. Device startup failures may have no screenshot; retain setup logs too.

## 15. Run and inspect the entire CI path

Push the branch and open a pull request. On GitHub, open **Actions → Flutter CI → the run**.

Check the stages in order: dependency installation, formatting/analyzer, fast tests, build validation, device startup, integration tests, report generation, and uploads. This demo runs fast widget/script checks in the Android workflow; the iOS workflow runs its own analysis, builds, and integration tests.

Inspect the Summary page and download both platforms’ artifacts. Confirm the number and names of tests match your test plan, and open the generated HTML and any failure images.

Temporarily introduce a failing assertion on the testing branch. Verify that the platform job and final combined job fail, the report shows failure, and diagnostics are uploaded. Restore the assertion and rerun. Also validate missing credentials and interrupted-result handling using the helper regression tests.

If retaining iOS retry behavior, ensure the first attempt remains available and a second-attempt pass is explicitly labeled. Investigate recurring retries rather than increasing retries to conceal flaky tests.

## 16. Make the checks part of the delivery process

Once stable, configure the repository’s branch protection or ruleset to require the actual combined check name displayed by GitHub. Agree on who investigates failures and updates tests when behavior changes.

Run the smoke suite on pull requests. Add broader scenarios as reliability and execution time allow. Keep manual exploratory testing for new behavior and areas automation does not cover.

## Completion checklist

- [ ] Existing app still runs with the testing changes.
- [ ] Manual cases map to automated scenarios with explicit assertions.
- [ ] Test accounts, data creation, reset, and cleanup are repeatable.
- [ ] Local Android and iOS test runs succeed.
- [ ] The same suite runs in GitHub Actions with the intended configuration.
- [ ] Summary, HTML, raw output, and process exit codes agree.
- [ ] An intentional failure fails CI and produces available diagnostics.
- [ ] Failure screenshots can be located in the artifacts.
- [ ] Temporary credentials are removed and kept out of Git.
- [ ] Required checks and failure ownership are agreed upon.

The implementation order is: one manual case → one local automated test → isolated suite → CI → reports and diagnostics → enforced team workflow.
