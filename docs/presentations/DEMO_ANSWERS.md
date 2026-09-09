# Demo answers: GitHub test results and failure screenshots

## Where did the results in the image come from?

The image shows a **GitHub Actions job summary** for `Android / Android Integration Tests`. The project’s Python report generator creates the table from Flutter test results and writes Markdown to `GITHUB_STEP_SUMMARY`. GitHub renders that Markdown on the workflow run’s Summary page.

The screenshot shows 12 tests, 12 passed, 0 failed, and a reported test-run duration of 73.12 seconds. That duration comes from Flutter’s machine-reporter timing; it is not the total CI job time, which also includes setup, builds, and emulator startup.

### Where to find it on GitHub

1. Open the repository’s [Actions page](https://github.com/berro-2/flutter-integration-testing/actions).
2. Select **Flutter CI** and open the relevant workflow run.
3. On the run’s **Summary** page, scroll below the workflow graph to **Android / Android Integration Tests summary**.
4. To inspect command output, select the Android job and expand **Run Android integration tests** or **Generate Android HTML report**.
5. To download files, use the run’s **Artifacts** section: `android-html-report` contains the generated report; `android-test-results` contains raw results and diagnostics.

The screenshot does not include a run number, commit, date, or URL. Its exact historical run could not be verified: the repository’s Actions page was unavailable through the web lookup. The source and type of summary are identifiable from the matching code and labels, but there is no verified link to that specific run.

### How the results reach GitHub

| Stage | Project source | What happens |
| --- | --- | --- |
| Start CI | `.github/workflows/flutter-ci.yml` | Pushes to `main` and pull requests targeting `main` invoke the Android and iOS workflows. |
| Run Android tests | `.github/workflows/android-tests.yml` and `scripts/ci/run_android_tests.sh` | Run the integration tests on an Android emulator with Flutter’s `--machine` reporter. |
| Save results | `scripts/ci/run_android_tests.sh` | Write machine events to `android_test_results.json`, stderr to `android_test_verbose.log`, and the process exit code to diagnostics. |
| Build the report | `scripts/test_reporting/generate_report.py` | Read the copied `test_reports/test_results.json`, calculate results and durations, and generate HTML plus `test_summary.md`. |
| Show the table | `build_markdown_summary()` and the generator’s final output block | Append the Markdown to the file named by `GITHUB_STEP_SUMMARY`. GitHub displays it as the job summary. |

Test names come from the nested `group(...)` and `testWidgets(...)` descriptions in `integration_test/task_test.dart` and `integration_test/suites/`.

The current source registers **13 integration scenarios**: 1 login, 4 dashboard/navigation, 4 creation/details/deletion, and 4 completion/statistics. The image’s 12-test table and fewer result columns are consistent with an older version of the project. The image does not prove that the current 13-test suite passed.

GitHub documents this rendering mechanism under [Adding a job summary](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands#adding-a-job-summary).

## Can the workflow capture screenshots when tests fail?

**Yes. This project already implements failure screenshot capture and artifact upload for Android and iOS.**

| Platform | Capture implementation | Where to find the image |
| --- | --- | --- |
| Android | After a nonzero test-command exit, `run_android_tests.sh` runs `adb -s emulator-5554 exec-out screencap -p`. | Download `android-test-results`; look for `android_diagnostics/failure.png`. |
| iOS | After each failed test attempt, `run_ios_tests.sh` runs `xcrun simctl io "$device_id" screenshot`. | Download `ios-test-results`; look under `ios_diagnostics/attempt-1/failure.png` or `attempt-2/failure.png`. |

Both workflow files use `actions/upload-artifact@v4` with `if: always()` for diagnostics and configure 14-day artifact retention. iOS permits two attempts and preserves the first failure even if the retry passes.

These screenshots capture the device **after the test command returns**. They are not screenshots of every failing assertion at the exact moment it fails. Capture is best-effort: an unavailable device, startup failure, or failure before test execution can leave no usable image. The screenshot supplied in the question is a results summary, not an app failure screenshot.

## Short explanation to use during the demo

“Flutter runs our integration scenarios on the emulator and writes machine-readable results. Our Python script turns those results into an HTML report and a Markdown job summary, which GitHub displays here. On a failed test run, our scripts also attempt to capture the device screen and upload it alongside the logs as a downloadable artifact.”
