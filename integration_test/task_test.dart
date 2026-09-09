import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'suites/completion_statistics_suite.dart';
import 'suites/dashboard_navigation_suite.dart';
import 'suites/login_suite.dart';
import 'suites/task_crud_suite.dart';
import 'support/task_test_driver.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Task manager integration tests', () {
    registerLoginSuite();
    registerDashboardNavigationSuite();
    registerTaskCrudSuite();
    registerCompletionStatisticsSuite();

    // TEMPORARY DEMO: remove this test after checking CI failure artifacts.
    // Keep it device-only so widget checks do not stop CI before capture.
    testWidgets('DEMO intentional failure for screenshot artifacts', (
      tester,
    ) async {
      final driver = TaskTestDriver(tester);
      await driver.startApp();
      driver.expectKeyedText('dashboard_total_tasks', '1');
    });
  });
}
