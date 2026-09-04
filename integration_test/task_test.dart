import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'suites/completion_statistics_suite.dart';
import 'suites/dashboard_navigation_suite.dart';
import 'suites/task_crud_suite.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Task manager integration tests', () {
    registerDashboardNavigationSuite();
    registerTaskCrudSuite();
    registerCompletionStatisticsSuite();
  });
}
