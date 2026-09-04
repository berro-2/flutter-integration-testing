import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/task_test_driver.dart';

void registerTaskCrudSuite() {
  group('Task creation, details, and deletion', () {
    testWidgets('adds a task and updates Dashboard counts', (tester) async {
      final driver = TaskTestDriver(tester);
      await driver.startApp();
      await driver.createTask(
        title: 'Prepare Flutter demo',
        description: 'Create integration test demo with multiple screens',
      );

      driver.expectKeyedText('dashboard_total_tasks', 'Total Tasks: 1');
      driver.expectKeyedText('dashboard_completed_tasks', 'Completed: 0');
      driver.expectKeyedText('dashboard_pending_tasks', 'Pending: 1');
    });

    testWidgets('uses a fallback when description is omitted', (tester) async {
      final driver = TaskTestDriver(tester);
      await driver.startApp();
      await driver.createTask(title: 'Task without description');
      await driver.openTaskList();
      await driver.tap(find.byKey(const Key('task_tile_0')));

      driver.expectKeyedText(
        'details_task_description',
        'No description provided',
      );
    });

    testWidgets('opens Task Details with the saved content', (tester) async {
      final driver = TaskTestDriver(tester);
      await driver.startApp();
      await driver.createTask(
        title: 'Open details test',
        description: 'This task is used to test the details screen',
      );
      await driver.openTaskList();
      await driver.tap(find.byKey(const Key('task_tile_0')));

      expect(find.byKey(const Key('task_details_screen')), findsOneWidget);
      driver.expectKeyedText('details_task_title', 'Open details test');
      driver.expectKeyedText(
        'details_task_description',
        'This task is used to test the details screen',
      );
      driver.expectKeyedText('details_task_status', 'Status: Pending');
    });

    testWidgets('deletes one task without removing the others', (tester) async {
      final driver = TaskTestDriver(tester);
      await driver.startApp();
      await driver.createTask(title: 'Task to delete');
      await driver.createTask(title: 'Task to keep');
      await driver.openTaskList();

      expect(find.text('Task to delete'), findsOneWidget);
      expect(find.text('Task to keep'), findsOneWidget);
      await driver.tap(find.byKey(const Key('delete_task_button_0')));

      expect(find.text('Task to delete'), findsNothing);
      driver.expectKeyedText('task_title_0', 'Task to keep');
      expect(find.byKey(const Key('empty_task_list_text')), findsNothing);
    });
  });
}
