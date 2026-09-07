import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/suites/completion_statistics_suite.dart';
import '../integration_test/suites/dashboard_navigation_suite.dart';
import '../integration_test/suites/login_suite.dart';
import '../integration_test/suites/task_crud_suite.dart';
import '../integration_test/support/task_test_driver.dart';

void main() {
  // Reuse the device scenarios for fast checks of the driver and UI assertions.
  registerLoginSuite();
  registerDashboardNavigationSuite();
  registerTaskCrudSuite();
  registerCompletionStatisticsSuite();

  testWidgets('driver reports a continuous animation instead of continuing', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const CircularProgressIndicator(),
              TextButton(onPressed: () {}, child: const Text('Tap')),
            ],
          ),
        ),
      ),
    );
    await expectLater(
      TaskTestDriver(tester).tap(find.text('Tap')),
      throwsA(
        isA<TestFailure>().having(
          (error) => error.message,
          'message',
          contains('UI did not settle'),
        ),
      ),
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
