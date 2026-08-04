class AppConstants {
  AppConstants._();

  // API
  static const String baseUrl =
      'https://apiservice.lemonglacier-62b8e153.westus2.azurecontainerapps.io/api';
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String userKey = 'auth_user';
  static const String tokenExpiresAtKey = 'token_expires_at';
  static const String onboardingDoneKey = 'onboarding_done';

  // Pagination
  static const int pageSize = 20;

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 150);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Currency
  static const String defaultCurrency = 'USD';
  static const String currencySymbol = '\$';
}
