import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/task_test_driver.dart';

void registerDashboardNavigationSuite() {
  group('Dashboard and navigation', () {
    testWidgets('shows an empty dashboard on startup', (tester) async {
      final driver = TaskTestDriver(tester);
      await driver.startApp();

      expect(find.text('Task Manager Dashboard'), findsOneWidget);
      driver.expectKeyedText('dashboard_total_tasks', 'Total Tasks: 0');
      driver.expectKeyedText('dashboard_completed_tasks', 'Completed: 0');
      driver.expectKeyedText('dashboard_pending_tasks', 'Pending: 0');
      expect(find.byKey(const Key('open_task_list_button')), findsOneWidget);
      expect(find.byKey(const Key('open_add_task_button')), findsOneWidget);
      expect(find.byKey(const Key('open_statistics_button')), findsOneWidget);
    });

    testWidgets('opens the empty Task List', (tester) async {
      final driver = TaskTestDriver(tester);
      await driver.startApp();
      await driver.openTaskList();

      expect(find.text('Tasks'), findsOneWidget);
      expect(find.byKey(const Key('empty_task_list_text')), findsOneWidget);
      expect(find.text('No tasks available'), findsOneWidget);
    });

    testWidgets('opens the Add Task screen', (tester) async {
      final driver = TaskTestDriver(tester);
      await driver.startApp();
      await driver.openAddTask();

      expect(find.text('Add Task'), findsOneWidget);
      expect(find.byKey(const Key('task_title_input')), findsOneWidget);
      expect(find.byKey(const Key('task_description_input')), findsOneWidget);
      expect(find.byKey(const Key('save_task_button')), findsOneWidget);
    });

    testWidgets('rejects an empty task title', (tester) async {
      final driver = TaskTestDriver(tester);
      await driver.startApp();
      await driver.openAddTask();
      await driver.tap(
        find.byKey(const Key('save_task_button')),
        dismissKeyboardFirst: true,
      );

      expect(find.byKey(const Key('error_message')), findsOneWidget);
      expect(find.text('Task title is required'), findsOneWidget);
      expect(find.byKey(const Key('add_task_screen')), findsOneWidget);
    });
  });
}
