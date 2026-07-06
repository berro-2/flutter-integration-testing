import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:integration_demo_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> startApp(WidgetTester tester) async {
    await tester.pumpWidget(
      const app.MyApp()
    );

    await tester.pumpAndSettle();
  }

  testWidgets('Dashboard screen loads successfully', (tester) async {
    await startApp(tester);

    expect(find.byKey(const Key('dashboard_screen')), findsOneWidget);
    expect(find.text('Task Manager Dashboard'), findsOneWidget);
    expect(find.text('Total Tasks: 0'), findsOneWidget);
    expect(find.text('Completed: 0'), findsOneWidget);
    expect(find.text('Pending: 0'), findsOneWidget);

    expect(find.byKey(const Key('open_task_list_button')), findsOneWidget);
    expect(find.byKey(const Key('open_add_task_button')), findsOneWidget);
    expect(find.byKey(const Key('open_statistics_button')), findsOneWidget);
  });

  testWidgets('User can navigate from Dashboard to Task List', (tester) async {
    await startApp(tester);

    await tester.tap(find.byKey(const Key('open_task_list_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('task_list_screen')), findsOneWidget);
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.byKey(const Key('empty_task_list_text')), findsOneWidget);
    expect(find.text('No tasks available'), findsOneWidget);
  });

  testWidgets('User can navigate from Dashboard to Add Task screen', (tester) async {
    await startApp(tester);

    await tester.tap(find.byKey(const Key('open_add_task_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('add_task_screen')), findsOneWidget);
    expect(find.text('Add Task'), findsOneWidget);
    expect(find.byKey(const Key('task_title_input')), findsOneWidget);
    expect(find.byKey(const Key('task_description_input')), findsOneWidget);
    expect(find.byKey(const Key('save_task_button')), findsOneWidget);
  });

  testWidgets('Empty task title shows validation message', (tester) async {
    await startApp(tester);

    await tester.tap(find.byKey(const Key('open_add_task_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('save_task_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('error_message')), findsOneWidget);
    expect(find.text('Task title is required'), findsOneWidget);
  });

  testWidgets('User can add a new task and see it on Dashboard', (tester) async {
    await startApp(tester);

    await tester.tap(find.byKey(const Key('open_add_task_button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('task_title_input')),
      'Prepare Flutter demo',
    );

    await tester.enterText(
      find.byKey(const Key('task_description_input')),
      'Create integration test demo with multiple screens',
    );

    await tester.tap(find.byKey(const Key('save_task_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dashboard_screen')), findsOneWidget);
    expect(find.text('Total Tasks: 1'), findsOneWidget);
    expect(find.text('Completed: 0'), findsOneWidget);
    expect(find.text('Pending: 1'), findsOneWidget);
  }); 

  testWidgets('User can add a task and see it in Task List', (tester) async {
    await startApp(tester);

    await tester.tap(find.byKey(const Key('open_add_task_button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('task_title_input')),
      'Task visible in list',
    );

    await tester.enterText(
      find.byKey(const Key('task_description_input')),
      'This task should appear in the list screen',
    );

    await tester.tap(find.byKey(const Key('save_task_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open_task_list_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('task_list_screen')), findsOneWidget);
    expect(find.text('Task visible in list'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.byKey(const Key('task_tile_0')), findsOneWidget);
  });

  testWidgets('User can open Task Details screen', (tester) async {
    await startApp(tester);

    await tester.tap(find.byKey(const Key('open_add_task_button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('task_title_input')),
      'Open details test',
    );

    await tester.enterText(
      find.byKey(const Key('task_description_input')),
      'This task is used to test the details screen',
    );

    await tester.tap(find.byKey(const Key('save_task_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open_task_list_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('task_tile_0')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('task_details_screen')), findsOneWidget);
    expect(find.text('Task Details'), findsOneWidget);
    expect(find.text('Open details test'), findsOneWidget);
    expect(find.text('This task is used to test the details screen'), findsOneWidget);
    expect(find.text('Status: Pending'), findsOneWidget);
  });

  testWidgets('User can mark task as completed from Task List', (tester) async {
    await startApp(tester);

    await tester.tap(find.byKey(const Key('open_add_task_button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('task_title_input')),
      'Complete from list',
    );

    await tester.enterText(
      find.byKey(const Key('task_description_input')),
      'Testing checkbox completion',
    );

    await tester.tap(find.byKey(const Key('save_task_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open_task_list_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('task_checkbox_0')));
    await tester.pumpAndSettle();

    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Pending'), findsNothing);
  });

  testWidgets('User can mark task as completed from Task Details', (tester) async {
    await startApp(tester);

    await tester.tap(find.byKey(const Key('open_add_task_button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('task_title_input')),
      'Complete from details',
    );

    await tester.enterText(
      find.byKey(const Key('task_description_input')),
      'Testing completion from details screen',
    );

    await tester.tap(find.byKey(const Key('save_task_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open_task_list_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('task_tile_0')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('task_details_screen')), findsOneWidget);
    expect(find.text('Status: Pending'), findsOneWidget);

    await tester.tap(find.byKey(const Key('details_toggle_complete_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('task_list_screen')), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
  });

  testWidgets('Statistics screen shows zero counts when no tasks exist', (tester) async {
    await startApp(tester);

    await tester.tap(find.byKey(const Key('open_statistics_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('statistics_screen')), findsOneWidget);
    expect(find.text('Statistics'), findsOneWidget);

    expect(find.byKey(const Key('statistics_total_tasks')), findsOneWidget);
    expect(find.byKey(const Key('statistics_completed_tasks')), findsOneWidget);
    expect(find.byKey(const Key('statistics_pending_tasks')), findsOneWidget);

    expect(find.text('0'), findsNWidgets(3));
  });

  testWidgets('Statistics screen shows correct counts after completing a task', (tester) async {
    await startApp(tester);

    await tester.tap(find.byKey(const Key('open_add_task_button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('task_title_input')),
      'Statistics task',
    );

    await tester.enterText(
      find.byKey(const Key('task_description_input')),
      'Testing statistics screen',
    );

    await tester.tap(find.byKey(const Key('save_task_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open_task_list_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('task_checkbox_0')));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open_statistics_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('statistics_screen')), findsOneWidget);

    expect(find.text('1'), findsNWidgets(2)); // total = 1, completed = 1
    expect(find.text('0'), findsOneWidget); // pending = 0
  });

  testWidgets('User can delete a task from Task List', (tester) async {
    await startApp(tester);

    await tester.tap(find.byKey(const Key('open_add_task_button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('task_title_input')),
      'Task to delete',
    );

    await tester.enterText(
      find.byKey(const Key('task_description_input')),
      'This task will be deleted',
    );

    await tester.tap(find.byKey(const Key('save_task_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open_task_list_button')));
    await tester.pumpAndSettle();

    expect(find.text('Task to delete'), findsOneWidget);

    await tester.tap(find.byKey(const Key('delete_task_button_0')));
    await tester.pumpAndSettle();

    expect(find.text('Task to delete'), findsNothing);
    expect(find.byKey(const Key('empty_task_list_text')), findsOneWidget);
  });
}