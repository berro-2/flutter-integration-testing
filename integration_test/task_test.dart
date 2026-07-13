import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:integration_demo_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> startApp(WidgetTester tester) async {
    // Remove the previous widget tree and navigation state.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    // Create a completely fresh app instance for every test.
    await tester.pumpWidget(
      app.MyApp(key: UniqueKey()),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('dashboard_screen')).hitTestable(),
      findsOneWidget,
      reason: 'Each test should start on the visible Dashboard screen.',
    );
  }

  Future<void> dismissKeyboard(WidgetTester tester) async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (tester.testTextInput.isRegistered) {
      tester.testTextInput.hide();
    }

    await tester.pump();
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(
    WidgetTester tester,
    Finder finder, {
    bool dismissKeyboardFirst = false,
  }) async {
    if (dismissKeyboardFirst) {
      await dismissKeyboard(tester);
    }

    await tester.pumpAndSettle();

    expect(
      finder,
      findsOneWidget,
      reason: 'Expected the target widget to exist before tapping.',
    );

    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();

    final hitTestableFinder = finder.hitTestable();

    expect(
      hitTestableFinder,
      findsOneWidget,
      reason:
          'The widget exists but is not currently visible or able to receive taps.',
    );

    await tester.tap(hitTestableFinder);
    await tester.pumpAndSettle();
  }

  Future<void> enterTaskDetails(
    WidgetTester tester, {
    required String title,
    required String description,
  }) async {
    final titleInput = find.byKey(const Key('task_title_input'));
    final descriptionInput =
        find.byKey(const Key('task_description_input'));

    expect(titleInput, findsOneWidget);
    expect(descriptionInput, findsOneWidget);

    await tester.enterText(titleInput, title);
    await tester.pump();

    await tester.enterText(descriptionInput, description);
    await tester.pump();
  }

  Future<void> openAddTaskScreen(WidgetTester tester) async {
    await tapVisible(
      tester,
      find.byKey(const Key('open_add_task_button')),
    );

    expect(
      find.byKey(const Key('add_task_screen')),
      findsOneWidget,
    );
  }

  Future<void> saveTask(WidgetTester tester) async {
    await tapVisible(
      tester,
      find.byKey(const Key('save_task_button')),
      dismissKeyboardFirst: true,
    );

    expect(
      find.byKey(const Key('dashboard_screen')).hitTestable(),
      findsOneWidget,
      reason: 'Saving the task should return to the visible Dashboard.',
    );
  }

  Future<void> createTask(
    WidgetTester tester, {
    required String title,
    required String description,
  }) async {
    await openAddTaskScreen(tester);

    await enterTaskDetails(
      tester,
      title: title,
      description: description,
    );

    await saveTask(tester);
  }

  Future<void> openTaskList(WidgetTester tester) async {
    await tapVisible(
      tester,
      find.byKey(const Key('open_task_list_button')),
    );

    expect(
      find.byKey(const Key('task_list_screen')),
      findsOneWidget,
    );
  }

  testWidgets(
    'Dashboard screen loads successfully',
    (tester) async {
      await startApp(tester);

      expect(
        find.byKey(const Key('dashboard_screen')),
        findsOneWidget,
      );
      expect(
        find.text('Task Manager Dashboard'),
        findsOneWidget,
      );
      expect(find.text('Total Tasks: 0'), findsOneWidget);
      expect(find.text('Completed: 0'), findsOneWidget);
      expect(find.text('Pending: 0'), findsOneWidget);

      expect(
        find.byKey(const Key('open_task_list_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('open_add_task_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('open_statistics_button')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'User can navigate from Dashboard to Task List',
    (tester) async {
      await startApp(tester);

      await openTaskList(tester);

      expect(find.text('Tasks'), findsOneWidget);
      expect(
        find.byKey(const Key('empty_task_list_text')),
        findsOneWidget,
      );
      expect(find.text('No tasks available'), findsOneWidget);
    },
  );

  testWidgets(
    'User can navigate from Dashboard to Add Task screen',
    (tester) async {
      await startApp(tester);

      await openAddTaskScreen(tester);

      expect(find.text('Add Task'), findsOneWidget);
      expect(
        find.byKey(const Key('task_title_input')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('task_description_input')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('save_task_button')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Empty task title shows validation message',
    (tester) async {
      await startApp(tester);

      await openAddTaskScreen(tester);

      await tapVisible(
        tester,
        find.byKey(const Key('save_task_button')),
        dismissKeyboardFirst: true,
      );

      expect(
        find.byKey(const Key('error_message')),
        findsOneWidget,
      );
      expect(
        find.text('Task title is required'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'User can add a new task and see it on Dashboard',
    (tester) async {
      await startApp(tester);

      await createTask(
        tester,
        title: 'Prepare Flutter demo',
        description:
            'Create integration test demo with multiple screens',
      );

      expect(find.text('Total Tasks: 1'), findsOneWidget);
      expect(find.text('Completed: 0'), findsOneWidget);
      expect(find.text('Pending: 1'), findsOneWidget);
    },
  );

  testWidgets(
    'User can add a task and see it in Task List',
    (tester) async {
      await startApp(tester);

      await createTask(
        tester,
        title: 'Task visible in list',
        description: 'This task should appear in the list screen',
      );

      await openTaskList(tester);

      expect(find.text('Task visible in list'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(
        find.byKey(const Key('task_tile_0')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'User can open Task Details screen',
    (tester) async {
      await startApp(tester);

      await createTask(
        tester,
        title: 'Open details test',
        description:
            'This task is used to test the details screen',
      );

      await openTaskList(tester);

      await tapVisible(
        tester,
        find.byKey(const Key('task_tile_0')),
      );

      expect(
        find.byKey(const Key('task_details_screen')),
        findsOneWidget,
      );
      expect(find.text('Task Details'), findsOneWidget);
      expect(find.text('Open details test'), findsOneWidget);
      expect(
        find.text(
          'This task is used to test the details screen',
        ),
        findsOneWidget,
      );
      expect(find.text('Status: Pending'), findsOneWidget);
    },
  );

  testWidgets(
    'User can mark task as completed from Task List',
    (tester) async {
      await startApp(tester);

      await createTask(
        tester,
        title: 'Complete from list',
        description: 'Testing checkbox completion',
      );

      await openTaskList(tester);

      await tapVisible(
        tester,
        find.byKey(const Key('task_checkbox_0')),
      );

      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Pending'), findsNothing);
    },
  );

  testWidgets(
    'User can mark task as completed from Task Details',
    (tester) async {
      await startApp(tester);

      await createTask(
        tester,
        title: 'Complete from details',
        description: 'Testing completion from details screen',
      );

      await openTaskList(tester);

      await tapVisible(
        tester,
        find.byKey(const Key('task_tile_0')),
      );

      expect(
        find.byKey(const Key('task_details_screen')),
        findsOneWidget,
      );
      expect(find.text('Status: Pending'), findsOneWidget);

      await tapVisible(
        tester,
        find.byKey(
          const Key('details_toggle_complete_button'),
        ),
      );

      expect(
        find.byKey(const Key('task_list_screen')),
        findsOneWidget,
      );
      expect(find.text('Completed'), findsOneWidget);
    },
  );

  testWidgets(
    'Statistics screen shows zero counts when no tasks exist',
    (tester) async {
      await startApp(tester);

      await tapVisible(
        tester,
        find.byKey(const Key('open_statistics_button')),
      );

      expect(
        find.byKey(const Key('statistics_screen')),
        findsOneWidget,
      );
      expect(find.text('Statistics'), findsOneWidget);
      expect(
        find.byKey(const Key('statistics_total_tasks')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('statistics_completed_tasks')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('statistics_pending_tasks')),
        findsOneWidget,
      );
      expect(find.text('0'), findsNWidgets(3));
    },
  );

  testWidgets(
    'Statistics screen shows correct counts after completing a task',
    (tester) async {
      await startApp(tester);

      await createTask(
        tester,
        title: 'Statistics task',
        description: 'Testing statistics screen',
      );

      await openTaskList(tester);

      await tapVisible(
        tester,
        find.byKey(const Key('task_checkbox_0')),
      );

      expect(find.text('Completed'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('dashboard_screen')).hitTestable(),
        findsOneWidget,
      );

      await tapVisible(
        tester,
        find.byKey(const Key('open_statistics_button')),
      );

      expect(
        find.byKey(const Key('statistics_screen')),
        findsOneWidget,
      );
      expect(find.text('1'), findsNWidgets(2));
      expect(find.text('0'), findsOneWidget);
    },
  );

  testWidgets(
    'User can delete a task from Task List',
    (tester) async {
      await startApp(tester);

      await createTask(
        tester,
        title: 'Task to delete',
        description: 'This task will be deleted',
      );

      await openTaskList(tester);

      expect(find.text('Task to delete'), findsOneWidget);

      await tapVisible(
        tester,
        find.byKey(const Key('delete_task_button_0')),
      );

      expect(find.text('Task to delete'), findsNothing);
      expect(
        find.byKey(const Key('empty_task_list_text')),
        findsOneWidget,
      );
    },
  );
}