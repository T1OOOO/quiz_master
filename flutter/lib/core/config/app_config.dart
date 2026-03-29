class AppConfig {
  static const String serverBaseUrl = String.fromEnvironment(
    'SERVER_BASE_URL',
    defaultValue: 'http://localhost:8090',
  );

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '$serverBaseUrl/api',
  );

  static const String authApiBaseUrl = String.fromEnvironment(
    'AUTH_API_BASE_URL',
    defaultValue: apiBaseUrl,
  );

  static const String quizApiBaseUrl = String.fromEnvironment(
    'QUIZ_API_BASE_URL',
    defaultValue: apiBaseUrl,
  );
}
