@echo off
set "PROJECT_DIR=C:\Users\96171\Desktop\flutter\integration_demo_app"
set "TEST_FILE=integration_test\task_test.dart"
set "DEVICE_ID=emulator-5554"

cd /d "%PROJECT_DIR%"

echo ========================================
echo Flutter Integration Test Runner
echo ========================================
echo Project: %PROJECT_DIR%
echo Test file: %TEST_FILE%
echo Device: %DEVICE_ID%
echo.

echo [1/3] Running Flutter integration tests and saving JSON...

call flutter test "%TEST_FILE%" -d %DEVICE_ID% --machine > "%PROJECT_DIR%\test_results.json" 2>&1

echo Flutter test command finished.
echo.

if not exist "%PROJECT_DIR%\test_results.json" (
    echo ERROR: test_results.json was not created.
    pause
    exit /b 1
)

echo JSON saved successfully:
echo %PROJECT_DIR%\test_results.json
echo.

echo [2/3] Generating HTML report...

call py "%PROJECT_DIR%\generate_report.py"

echo.

if not exist "%PROJECT_DIR%\latest_report_name.txt" (
    echo ERROR: latest_report_name.txt was not created.
    pause
    exit /b 1
)

set /p REPORT_FILE=<"%PROJECT_DIR%\latest_report_name.txt"

if not exist "%REPORT_FILE%" (
    echo ERROR: HTML report was not created.
    echo Expected:
    echo %REPORT_FILE%
    pause
    exit /b 1
)

echo HTML report generated successfully:
echo %REPORT_FILE%
echo.

echo [3/3] Opening HTML report...

start "" "%REPORT_FILE%"

echo.
echo Done.
pause