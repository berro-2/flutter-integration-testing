class DemoCredentials {
  DemoCredentials._();

  static const username = String.fromEnvironment(
    'DEMO_LOGIN_USERNAME',
    defaultValue: 'local-demo-user',
  );
  static const password = String.fromEnvironment(
    'DEMO_LOGIN_PASSWORD',
    defaultValue: 'local-demo-password',
  );
  static const requireInjected = bool.fromEnvironment(
    'REQUIRE_DEMO_CREDENTIALS',
  );

  static bool get isConfigured => username.isNotEmpty && password.isNotEmpty;
}
