import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_demo_app/main.dart' as app;

class TaskTestDriver {
  TaskTestDriver(this.tester);

  final WidgetTester tester;

  Future<void> startApp() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await tester.pumpWidget(app.MyApp(key: UniqueKey()));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('dashboard_screen')).hitTestable(),
      findsOneWidget,
      reason: 'Each test should start on the visible Dashboard screen.',
    );
  }

  Future<void> tap(Finder finder, {bool dismissKeyboardFirst = false}) async {
    if (dismissKeyboardFirst) {
      await dismissKeyboard();
    }

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
      reason: 'The target widget is not visible or cannot receive taps.',
    );

    await tester.tap(hitTestableFinder);
    await tester.pumpAndSettle();
  }

  Future<void> dismissKeyboard() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (tester.testTextInput.isRegistered) {
      tester.testTextInput.hide();
    }
    await tester.pump();
  }

  Future<void> openAddTask() async {
    await tap(find.byKey(const Key('open_add_task_button')));
    expect(find.byKey(const Key('add_task_screen')), findsOneWidget);
  }

  Future<void> createTask({
    required String title,
    String description = '',
  }) async {
    await openAddTask();

    await tester.enterText(find.byKey(const Key('task_title_input')), title);
    if (description.isNotEmpty) {
      await tester.enterText(
        find.byKey(const Key('task_description_input')),
        description,
      );
    }

    await tap(
      find.byKey(const Key('save_task_button')),
      dismissKeyboardFirst: true,
    );
    expect(
      find.byKey(const Key('dashboard_screen')).hitTestable(),
      findsOneWidget,
      reason: 'Saving a task should return to the Dashboard.',
    );
  }

  Future<void> openTaskList() async {
    await tap(find.byKey(const Key('open_task_list_button')));
    expect(find.byKey(const Key('task_list_screen')), findsOneWidget);
  }

  Future<void> openStatistics() async {
    await tap(find.byKey(const Key('open_statistics_button')));
    expect(find.byKey(const Key('statistics_screen')), findsOneWidget);
  }

  Future<void> goBack() async {
    await tester.pageBack();
    await tester.pumpAndSettle();
  }

  void expectKeyedText(String key, String expectedText) {
    final finder = find.byKey(Key(key));
    expect(finder, findsOneWidget);
    expect(tester.widget<Text>(finder).data, expectedText);
  }
}
