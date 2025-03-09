class AppConfig {
  // API configurations
  static String get apiBaseUrl => const String.fromEnvironment('API_BASE_URL');
  static const int connectTimeout = 15000; // in milliseconds
  static const int receiveTimeout = 15000;

  // App version
  static const String appVersion = '1.0.0';

  // Google OAuth Client
  static String get googleClientId =>
      const String.fromEnvironment('GOOGLE_CLIENT_ID');
}
