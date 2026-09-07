import json
import os
import html as html_escape
from datetime import datetime

script_dir = os.path.dirname(os.path.abspath(__file__))
project_dir = os.path.abspath(os.path.join(script_dir, "..", ".."))

reports_folder = os.path.abspath(os.environ.get("TEST_REPORTS_DIR", os.path.join(project_dir, "test_reports")))
os.makedirs(reports_folder, exist_ok=True)
latest_file = os.path.join(reports_folder, "latest_report_name.txt")
# A failed generation must never leave a pointer to a previous run.
if os.path.exists(latest_file):
    os.remove(latest_file)
input_file = os.path.join(reports_folder, "test_results.json")

timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S_%f")
output_file = os.path.join(reports_folder, f"test_report_{timestamp}.html")

tests = {}
final_success = False
run_completed = False
total_time = 0
raw_logs = []
error_logs = []


def safe_text(value):
    return html_escape.escape(str(value))


def get_display_result(test):
    result = test.get("result", "unknown")

    if test.get("skipped", False):
        return "SKIPPED"
    if test.get("has_error", False) or result in ("failure", "error"):
        return "FAILED"
    if result == "success":
        return "PASSED"
    return "INTERRUPTED"


def get_row_class(test):
    display = get_display_result(test)

    return display.lower() + "-row"


with open(input_file, "r", encoding="utf-8", errors="ignore") as file:
    for line in file:
        original_line = line.rstrip("\n")
        raw_logs.append(original_line)

        line = line.strip()

        if not line:
            continue

        try:
            data = json.loads(line)
        except json.JSONDecodeError:
            lower_line = line.lower()

            if (
                "exception" in lower_line
                or "error" in lower_line
                or "failed" in lower_line
                or "failure" in lower_line
                or "traceback" in lower_line
                or "crash" in lower_line
            ):
                error_logs.append(original_line)

            continue

        if isinstance(data, list):
            continue

        if not isinstance(data, dict):
            continue

        event_type = data.get("type")

        if event_type == "testStart":
            test = data.get("test", {})
            test_id = test.get("id")
            test_name = test.get("name")

            if test_id is not None and test_name:
                tests[test_id] = {
                    "id": test_id,
                    "name": test_name,
                    "result": "running",
                    "skipped": bool(test.get("metadata", {}).get("skip", False)),
                    "hidden": False,
                    "start_time": data.get("time", 0),
                    "end_time": None,
                    "duration": None,
                    "logs": [],
                }

        elif event_type == "testDone":
            test_id = data.get("testID")

            if test_id in tests:
                tests[test_id]["result"] = data.get("result", "unknown")
                tests[test_id]["skipped"] = data.get("skipped", False) or tests[test_id]["skipped"]
                tests[test_id]["hidden"] = data.get("hidden", False)
                tests[test_id]["end_time"] = data.get("time", 0)

                start_time = tests[test_id]["start_time"]
                end_time = tests[test_id]["end_time"]
                tests[test_id]["duration"] = end_time - start_time

        elif event_type == "print":
            test_id = data.get("testID")
            message = data.get("message", "")

            if test_id in tests:
                tests[test_id]["logs"].append(message)

            lower_message = str(message).lower()

            if (
                "exception" in lower_message
                or "error" in lower_message
                or "failed" in lower_message
                or "failure" in lower_message
                or "traceback" in lower_message
                or "crash" in lower_message
            ):
                error_logs.append(message)

        elif event_type == "error":
            message = data.get("error", "")
            stack_trace = data.get("stackTrace", "")

            error_text = f"{message}\n{stack_trace}"
            error_logs.append(error_text)

            test_id = data.get("testID")
            if test_id in tests:
                tests[test_id]["logs"].append(error_text)
                tests[test_id]["has_error"] = True

        elif event_type == "done":
            run_completed = True
            final_success = data.get("success", False)
            total_time = data.get("time", 0)


visible_tests = [
    test for test in tests.values()
    if not test["name"].startswith("loading")
    and not test["name"].startswith("(tearDownAll)")
    and not test.get("hidden", False)
]

passed_tests_list = [
    test for test in visible_tests
    if get_display_result(test) == "PASSED"
]

failed_tests_list = [
    test for test in visible_tests
    if get_display_result(test) == "FAILED"
]

total_tests = len(visible_tests)
passed_tests = len(passed_tests_list)
failed_tests = len(failed_tests_list)
skipped_tests = sum(get_display_result(test) == "SKIPPED" for test in visible_tests)
interrupted_tests = sum(get_display_result(test) == "INTERRUPTED" for test in visible_tests)

final_success = final_success and not failed_tests and not interrupted_tests
process_exit_code = os.environ.get("TEST_PROCESS_EXIT_CODE", "0")
if process_exit_code != "0":
    final_success = False
status_text = "INTERRUPTED" if not run_completed else ("PASSED" if final_success else "FAILED")
run_note = os.environ.get("TEST_RUN_NOTE", "")
if process_exit_code != "0":
    run_note += f" Flutter command exited with code {process_exit_code}."
if final_success and os.environ.get("TEST_PASSED_ON_RETRY") == "true":
    status_text = "PASSED ON RETRY"
    run_note = "An earlier attempt failed. Inspect the per-attempt results and diagnostics."
status_class = "passed" if final_success else "failed"
platform_name = os.environ.get("TEST_PLATFORM", "Flutter")


def markdown_text(value):
    return str(value).replace("|", "\\|").replace("\r", " ").replace("\n", " ")


def build_markdown_summary():
    status_icon = "✅" if final_success else "❌"
    lines = [
        f"## {platform_name} integration tests",
        "",
        f"### {status_icon} Overall result: {status_text}",
        "",
        run_note,
        "",
        "| Total | Passed | Failed | Skipped | Interrupted | Duration |",
        "| ---: | ---: | ---: | ---: | ---: | ---: |",
        (
            f"| {total_tests} | {passed_tests} | {failed_tests} | "
            f"{skipped_tests} | {interrupted_tests} | "
            f"{round(total_time / 1000, 2)}s |"
        ),
        "",
        "### Test results",
        "",
        "| Test | Result | Duration |",
        "| --- | :---: | ---: |",
    ]

    if visible_tests:
        for test in visible_tests:
            display_result = get_display_result(test)
            result_icon = {"PASSED": "✅", "FAILED": "❌", "SKIPPED": "⏭", "INTERRUPTED": "⚠"}[display_result]
            duration_ms = test["duration"] if test["duration"] is not None else 0
            lines.append(
                f"| {markdown_text(test['name'])} | "
                f"{result_icon} {display_result} | {round(duration_ms / 1000, 2)}s |"
            )
    else:
        lines.append(f"| No test cases were recorded. | {status_text} | — |")

    problem_tests = failed_tests_list + [test for test in visible_tests if get_display_result(test) == "INTERRUPTED"]
    if problem_tests:
        lines.extend(["", "### Failure details", ""])

        for test in problem_tests:
            logs = "\n".join(test.get("logs", [])).strip()
            if not logs:
                logs = "No per-test failure output was recorded. Check the job log."

            # Keep the Actions summary useful without approaching GitHub's size limit.
            logs = logs[-12000:]
            lines.extend(
                [
                    "<details>",
                    f"<summary>{safe_text(test['name'])}</summary>",
                    "",
                    f"<pre>{safe_text(logs)}</pre>",
                    "</details>",
                    "",
                ]
            )

    if not final_success and error_logs:
        combined_errors = "\n\n".join(error_logs)[-12000:]
        lines.extend(
            [
                "<details>",
                "<summary>All captured errors</summary>",
                "",
                f"<pre>{safe_text(combined_errors)}</pre>",
                "</details>",
                "",
            ]
        )

    return "\n".join(lines).rstrip() + "\n"


def build_test_rows(test_list):
    if not test_list:
        return """
        <tr>
            <td colspan="5" class="empty-table">No test cases in this group.</td>
        </tr>
        """

    rows = ""

    for index, test in enumerate(test_list, start=1):
        display_result = get_display_result(test)
        row_class = get_row_class(test)

        duration_ms = test["duration"] if test["duration"] is not None else 0
        duration_seconds = round(duration_ms / 1000, 2)

        logs = "\n".join(test.get("logs", []))
        logs_html = safe_text(logs) if logs else "No logs for this test."

        rows += f"""
        <tr class="{row_class}">
            <td>{index}</td>
            <td>{safe_text(test["name"])}</td>
            <td><span class="badge {display_result.lower()}">{display_result}</span></td>
            <td>{duration_seconds}s</td>
            <td>
                <details>
                    <summary>View logs</summary>
                    <pre>{logs_html}</pre>
                </details>
            </td>
        </tr>
        """

    return rows


all_rows = build_test_rows(visible_tests)
passed_rows = build_test_rows(passed_tests_list)
failed_rows = build_test_rows(failed_tests_list)

all_logs_html = safe_text("\n".join(raw_logs)) if raw_logs else "No logs available."
error_logs_html = safe_text("\n\n".join(error_logs)) if error_logs else "No crash or error logs detected."

html = f"""
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Flutter Integration Test Report</title>

    <style>
        body {{
            font-family: Arial, sans-serif;
            background-color: #f4f6f8;
            margin: 0;
            padding: 30px;
        }}

        .container {{
            max-width: 1200px;
            margin: auto;
            background-color: white;
            padding: 30px;
            border-radius: 12px;
            box-shadow: 0 4px 14px rgba(0, 0, 0, 0.1);
        }}

        h1 {{
            margin-bottom: 5px;
        }}

        .date {{
            color: #666;
            margin-bottom: 25px;
        }}

        .summary {{
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 15px;
            margin-bottom: 30px;
        }}

        .card {{
            background-color: #f8f9fb;
            padding: 18px;
            border-radius: 10px;
            text-align: center;
            border: 1px solid #ddd;
        }}

        .card h2 {{
            margin: 0;
            font-size: 28px;
        }}

        .card p {{
            margin: 5px 0 0;
            color: #666;
        }}

        .passed {{
            color: #198754;
            font-weight: bold;
        }}

        .failed {{
            color: #dc3545;
            font-weight: bold;
        }}

        .tabs {{
            display: flex;
            gap: 8px;
            margin-bottom: 20px;
            border-bottom: 1px solid #ddd;
            flex-wrap: wrap;
        }}

        .tab-button {{
            background-color: #f0f2f5;
            border: 1px solid #ddd;
            border-bottom: none;
            padding: 12px 18px;
            cursor: pointer;
            border-radius: 8px 8px 0 0;
            font-weight: bold;
        }}

        .tab-button.active {{
            background-color: #222;
            color: white;
        }}

        .tab-content {{
            display: none;
        }}

        .tab-content.active {{
            display: block;
        }}

        table {{
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }}

        th {{
            background-color: #222;
            color: white;
            padding: 12px;
            text-align: left;
        }}

        td {{
            padding: 12px;
            border-bottom: 1px solid #ddd;
            vertical-align: top;
        }}

        .passed-row {{
            background-color: #eaf7ee;
        }}

        .failed-row {{
            background-color: #fdeaea;
        }}

        .badge {{
            display: inline-block;
            padding: 5px 10px;
            border-radius: 999px;
            font-size: 12px;
            font-weight: bold;
            color: white;
        }}

        .badge.passed {{
            background-color: #198754;
        }}

        .badge.failed {{
            background-color: #dc3545;
        }}
        .badge.skipped {{ background-color: #596579; }}
        .badge.interrupted {{ background-color: #946200; }}
        .skipped-row {{ background-color: #eef1f5; }}
        .interrupted-row {{ background-color: #fff4d6; }}

        pre {{
            background-color: #111;
            color: #eee;
            padding: 15px;
            border-radius: 8px;
            overflow-x: auto;
            white-space: pre-wrap;
            font-size: 13px;
        }}

        details summary {{
            cursor: pointer;
            font-weight: bold;
        }}

        .empty-table {{
            text-align: center;
            color: #777;
            padding: 25px;
        }}

        .footer {{
            margin-top: 30px;
            color: #777;
            font-size: 14px;
        }}

        .status-box {{
            padding: 18px;
            border-radius: 10px;
            margin-bottom: 20px;
            background-color: #f8f9fb;
            border: 1px solid #ddd;
        }}
    </style>

    <script>
        function openTab(tabId, buttonElement) {{
            const tabs = document.querySelectorAll('.tab-content');
            const buttons = document.querySelectorAll('.tab-button');

            tabs.forEach(tab => tab.classList.remove('active'));
            buttons.forEach(button => button.classList.remove('active'));

            document.getElementById(tabId).classList.add('active');
            buttonElement.classList.add('active');
        }}
    </script>
</head>

<body>
    <div class="container">
        <h1>Flutter Integration Test Report</h1>
        <div class="date">Generated on {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}</div>

        <div class="status-box">
            <h2 class="{status_class}">Overall Result: {status_text}</h2>
            <p>{safe_text(run_note)}</p>
        </div>

        <div class="tabs">
            <button class="tab-button active" onclick="openTab('summaryTab', this)">Summary</button>
            <button class="tab-button" onclick="openTab('allTestsTab', this)">All Tests</button>
            <button class="tab-button" onclick="openTab('passedTab', this)">Passed</button>
            <button class="tab-button" onclick="openTab('failedTab', this)">Failed</button>
            <button class="tab-button" onclick="openTab('logsTab', this)">Logs</button>
        </div>

        <div id="summaryTab" class="tab-content active">
            <div class="summary">
                <div class="card">
                    <h2>{total_tests}</h2>
                    <p>Total Tests</p>
                </div>

                <div class="card">
                    <h2>{passed_tests}</h2>
                    <p>Passed</p>
                </div>

                <div class="card">
                    <h2>{failed_tests}</h2>
                    <p>Failed</p>
                </div>
                <div class="card"><h2>{skipped_tests}</h2><p>Skipped</p></div>
                <div class="card"><h2>{interrupted_tests}</h2><p>Interrupted</p></div>

                <div class="card">
                    <h2>{round(total_time / 1000, 2)}s</h2>
                    <p>Total Time</p>
                </div>
            </div>

        
        </div>

        <div id="allTestsTab" class="tab-content">
            <h2>All Test Cases</h2>
            <table>
                <thead>
                    <tr>
                        <th>#</th>
                        <th>Test Case</th>
                        <th>Result</th>
                        <th>Duration</th>
                        <th>Logs</th>
                    </tr>
                </thead>
                <tbody>
                    {all_rows}
                </tbody>
            </table>
        </div>

        <div id="passedTab" class="tab-content">
            <h2>Passed Test Cases</h2>
            <table>
                <thead>
                    <tr>
                        <th>#</th>
                        <th>Test Case</th>
                        <th>Result</th>
                        <th>Duration</th>
                        <th>Logs</th>
                    </tr>
                </thead>
                <tbody>
                    {passed_rows}
                </tbody>
            </table>
        </div>

        <div id="failedTab" class="tab-content">
            <h2>Failed Test Cases</h2>
            <table>
                <thead>
                    <tr>
                        <th>#</th>
                        <th>Test Case</th>
                        <th>Result</th>
                        <th>Duration</th>
                        <th>Logs</th>
                    </tr>
                </thead>
                <tbody>
                    {failed_rows}
                </tbody>
            </table>

            <h2>Crash / Error Logs</h2>
            <pre>{error_logs_html}</pre>
        </div>

        <div id="logsTab" class="tab-content">
            <h2>Full Raw Logs</h2>
            <pre>{all_logs_html}</pre>
        </div>

        <div class="footer">
            Generated from Flutter machine test output: test_results.json
        </div>
    </div>
</body>
</html>
"""

with open(output_file, "w", encoding="utf-8") as file:
    file.write(html)

markdown_summary = build_markdown_summary()
summary_output_file = os.path.join(reports_folder, "test_summary.md")

with open(summary_output_file, "w", encoding="utf-8") as file:
    file.write(markdown_summary)

github_summary_file = os.environ.get("GITHUB_STEP_SUMMARY")
if github_summary_file:
    with open(github_summary_file, "a", encoding="utf-8") as file:
        file.write(markdown_summary)

latest_file = os.path.join(reports_folder, "latest_report_name.txt")

with open(latest_file, "w", encoding="utf-8") as file:
    file.write(output_file)

print(f"HTML report generated: {output_file}")
print(f"Markdown summary generated: {summary_output_file}")
