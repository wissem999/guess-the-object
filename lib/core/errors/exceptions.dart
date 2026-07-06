class ServerException implements Exception {
  final String message;
  final int? statusCode;
  ServerException(this.message, {this.statusCode});
}

class CacheException implements Exception {
  final String message;
  CacheException(this.message);
}

class AuthException implements Exception {
  final String message;
  final String? code;
  AuthException(this.message, {this.code});
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
}
