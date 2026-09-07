import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/task_test_driver.dart';

void registerLoginSuite() {
  group('Login', () {
    testWidgets('rejects invalid credentials', (tester) async {
      final driver = TaskTestDriver(tester);
      await driver.launchApp();
      await driver.login(username: 'wrong-user', password: 'wrong-password');

      expect(find.byKey(const Key('login_screen')), findsOneWidget);
      expect(find.byKey(const Key('login_error')), findsOneWidget);
      expect(find.text('Invalid username or password.'), findsOneWidget);
      expect(find.byKey(const Key('dashboard_screen')), findsNothing);
    });
  });
}
