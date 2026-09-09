import 'package:flutter/foundation.dart' show debugPrintSynchronously;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_demo_app/main.dart' as app;
import 'package:integration_demo_app/config/demo_credentials.dart';
import 'package:integration_test/integration_test.dart';

const _failureScreenshotMarker = 'CI_SCREENSHOT_REQUEST:';
const _failureScreenshotWindow = Duration(seconds: 3);

void scenarioTestWidgets(String description, WidgetTesterCallback callback) {
  testWidgets(description, (tester) async {
    try {
      await callback(tester);
    } catch (error, stackTrace) {
      if (tester.binding is IntegrationTestWidgetsFlutterBinding) {
        final screenshotName = description
            .toLowerCase()
            .replaceAll(RegExp('[^a-z0-9]+'), '-')
            .replaceAll(RegExp(r'^-+|-+$'), '');

        // The CI runner watches Flutter's machine output for this marker and
        // captures the device while this test is still active.
        debugPrintSynchronously('$_failureScreenshotMarker$screenshotName');
        await Future<void>.delayed(_failureScreenshotWindow);
      }

      Error.throwWithStackTrace(error, stackTrace);
    }
  });
}

class TaskTestDriver {
  TaskTestDriver(this.tester);

  static const _pollInterval = Duration(milliseconds: 100);
  static const _maximumPolls = 20;

  final WidgetTester tester;

  Future<void> _settle() async {
    for (var attempt = 0; attempt < _maximumPolls; attempt++) {
      await tester.pump(_pollInterval);
      if (!tester.binding.hasScheduledFrame) {
        return;
      }
    }
    fail(
      'UI did not settle after $_maximumPolls pumps '
      '(${_maximumPolls * _pollInterval.inMilliseconds} ms of frame waits). '
      'Frames are still scheduled; check for a continuous animation or '
      'an unfinished transition.',
    );
  }

  Future<void> _waitUntil(
    bool Function() condition, {
    required String failureReason,
  }) async {
    for (var attempt = 0; attempt < _maximumPolls; attempt++) {
      if (condition()) {
        return;
      }
      await tester.pump(_pollInterval);
    }

    expect(condition(), isTrue, reason: failureReason);
  }

  Future<void> startApp() async {
    await launchApp();
    await login();
  }

  Future<void> launchApp() async {
    if (DemoCredentials.requireInjected) {
      expect(
        DemoCredentials.isConfigured,
        isTrue,
        reason:
            'CI requires DEMO_LOGIN_USERNAME and DEMO_LOGIN_PASSWORD to be '
            'injected with --dart-define-from-file.',
      );
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await _settle();

    await tester.pumpWidget(app.MyApp(key: UniqueKey()));
    await _settle();

    expect(
      find.byKey(const Key('login_screen')).hitTestable(),
      findsOneWidget,
      reason: 'Each test should start on the visible Login screen.',
    );
  }

  Future<void> login({
    String username = DemoCredentials.username,
    String password = DemoCredentials.password,
  }) async {
    await tester.enterText(
      find.byKey(const Key('login_username_input')),
      username,
    );
    await tester.enterText(
      find.byKey(const Key('login_password_input')),
      password,
    );
    await tap(
      find.byKey(const Key('login_submit_button')),
      dismissKeyboardFirst: true,
    );
    if (username == DemoCredentials.username &&
        password == DemoCredentials.password) {
      expect(
        find.byKey(const Key('dashboard_screen')).hitTestable(),
        findsOneWidget,
        reason: 'Valid demo credentials should open the Dashboard.',
      );
    }
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
    await _settle();

    await _waitUntil(
      () => finder.hitTestable().evaluate().length == 1,
      failureReason:
          'The target widget did not become visible and tappable within '
          '${_maximumPolls * _pollInterval.inMilliseconds} ms.',
    );

    await tester.tap(finder.hitTestable());
    await _settle();
  }

  Future<void> dismissKeyboard() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (tester.testTextInput.isRegistered) {
      tester.testTextInput.hide();
    }

    await _waitUntil(
      () => tester.view.viewInsets.bottom == 0,
      failureReason:
          'The software keyboard did not close within '
          '${_maximumPolls * _pollInterval.inMilliseconds} ms.',
    );
    await _settle();
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

    final dashboard = find.byKey(const Key('dashboard_screen'));
    await _waitUntil(
      () => dashboard.hitTestable().evaluate().length == 1,
      failureReason: 'Saving a task did not return to the visible Dashboard.',
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
    await _settle();
  }

  void expectKeyedText(String key, String expectedText) {
    final finder = find.byKey(Key(key));
    expect(finder, findsOneWidget);
    expect(tester.widget<Text>(finder).data, expectedText);
  }
}
