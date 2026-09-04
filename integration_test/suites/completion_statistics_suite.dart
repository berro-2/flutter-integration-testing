import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/task_test_driver.dart';

void registerCompletionStatisticsSuite() {
  group('Task completion and statistics', () {
    testWidgets('marks a task completed from Task List', (tester) async {
      final driver = TaskTestDriver(tester);
      await driver.startApp();
      await driver.createTask(title: 'Complete from list');
      await driver.openTaskList();
      await driver.tap(find.byKey(const Key('task_checkbox_0')));

      driver.expectKeyedText('task_status_0', 'Completed');
    });

    testWidgets('marks a task completed from Task Details', (tester) async {
      final driver = TaskTestDriver(tester);
      await driver.startApp();
      await driver.createTask(title: 'Complete from details');
      await driver.openTaskList();
      await driver.tap(find.byKey(const Key('task_tile_0')));

      driver.expectKeyedText('details_task_status', 'Status: Pending');
      await driver.tap(find.byKey(const Key('details_toggle_complete_button')));

      expect(find.byKey(const Key('task_list_screen')), findsOneWidget);
      driver.expectKeyedText('task_status_0', 'Completed');
    });

    testWidgets('shows zero statistics when no tasks exist', (tester) async {
      final driver = TaskTestDriver(tester);
      await driver.startApp();
      await driver.openStatistics();

      driver.expectKeyedText('statistics_total_tasks', '0');
      driver.expectKeyedText('statistics_completed_tasks', '0');
      driver.expectKeyedText('statistics_pending_tasks', '0');
      expect(find.text('0% completed'), findsOneWidget);
    });

    testWidgets('shows correct statistics for mixed task states', (
      tester,
    ) async {
      final driver = TaskTestDriver(tester);
      await driver.startApp();
      await driver.createTask(title: 'Completed task');
      await driver.createTask(title: 'Pending task');
      await driver.openTaskList();
      await driver.tap(find.byKey(const Key('task_checkbox_0')));
      await driver.goBack();
      await driver.openStatistics();

      driver.expectKeyedText('statistics_total_tasks', '2');
      driver.expectKeyedText('statistics_completed_tasks', '1');
      driver.expectKeyedText('statistics_pending_tasks', '1');
      expect(find.text('50% completed'), findsOneWidget);
    });
  });
}
