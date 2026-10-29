enum Environment {
  development,
  staging,
  production,
}

class AppConfig {
  static Environment _environment = Environment.staging;
  static String? _customBaseUrl;

  static Environment get environment => _environment;

  static void setEnvironment(Environment env) {
    _environment = env;
  }

  static void setCustomBaseUrl(String? url) {
    _customBaseUrl = url;
  }

  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }
    switch (_environment) {
      case Environment.development:
        return 'http://10.0.2.2:8080/api/v1'; // Android emulator localhost
      case Environment.staging:
        return 'https://backend-gadt.onrender.com/api/v1';
      case Environment.production:
        return 'https://backend-gadt.onrender.com/api/v1'; // Until production URL is provided
    }
  }

  // Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String userMeEndpoint = '/users/me';
  static const String goalsEndpoint = '/goals';
  static const String walletsEndpoint = '/wallets';
  static const String quotesEndpoint = '/quotes';
  static const String transactionsEndpoint = '/transactions';
  static const String webhooksEndpoint = '/webhooks';
}
