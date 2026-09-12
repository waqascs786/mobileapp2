class ApiConfig {
  ApiConfig._();

  static const String _baseUrl = 'https://api.pagepilot.com/v1';

  static String get baseUrl => _baseUrl;

  static const Map<String, String> endpoints = {
    'courses': '/courses',
    'courseDetail': '/courses/{id}',
    'lessons': '/courses/{courseId}/lessons',
    'quizzes': '/courses/{courseId}/quizzes',
    'quizDetail': '/quizzes/{id}',
    'quizSubmit': '/quizzes/{id}/submit',
    'auth': '/auth/login',
    'register': '/auth/register',
    'refreshToken': '/auth/refresh',
    'profile': '/user/profile',
    'updateProfile': '/user/profile',
    'wishlist': '/user/wishlist',
    'wishlistAdd': '/user/wishlist/{courseId}',
    'wishlistRemove': '/user/wishlist/{courseId}',
    'progress': '/user/progress/{courseId}',
    'progressUpdate': '/user/progress/{courseId}',
    'categories': '/categories',
    'search': '/search',
  };

  static String buildUrl(String endpointKey, {Map<String, String>? pathParams}) {
    String? endpoint = endpoints[endpointKey];
    if (endpoint == null) {
      throw ArgumentError('Unknown endpoint key: $endpointKey');
    }

    if (pathParams != null) {
      pathParams.forEach((key, value) {
        endpoint = endpoint!.replaceAll('{$key}', value);
      });
    }

    return '$_baseUrl$endpoint';
  }

  static Map<String, String> authHeaders({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  static Map<String, String> buildHeaders({String? token, Map<String, String>? extra}) {
    final headers = authHeaders(token: token);
    if (extra != null) {
      headers.addAll(extra);
    }
    return headers;
  }

  static Duration get timeout => const Duration(seconds: 30);

  static int get maxRetries => 3;

  static Duration retryDelay(int attempt) {
    return Duration(seconds: (1 << attempt));
  }
}
