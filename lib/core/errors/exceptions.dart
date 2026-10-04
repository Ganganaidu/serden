class ServerException implements Exception {
  final String message;
  final int? statusCode;
  ServerException(this.message, {this.statusCode});
}

/// 4xx `{"error": "SubscriptionLimitReached", "used": n, "limit": n}`.
class SubscriptionLimitException extends ServerException {
  final int? used;
  final int? limit;
  SubscriptionLimitException(super.message,
      {super.statusCode, this.used, this.limit});
}

class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = 'No internet connection']);
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException([this.message = 'Unauthorized']);
}

class CacheException implements Exception {
  final String message;
  CacheException([this.message = 'Cache error']);
}
