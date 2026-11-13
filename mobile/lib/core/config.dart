/// Runtime configuration for the patient app.
class AppConfig {
  const AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api/v1',
  );

  /// Set only on a demo build. Empty in the normal app, which still uses a real code.
  static const String demoOtp = String.fromEnvironment('DEMO_OTP');

  /// One phone-test account. It never calls the server.
  static const String testMobileDigits = '9999999999';
  static const String testOtp = '123456';
}
