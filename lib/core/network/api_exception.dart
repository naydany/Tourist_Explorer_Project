sealed class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class NetworkException extends ApiException {
  const NetworkException([super.message = 'Could not reach the server.']);
}

final class ApiStatusException extends ApiException {
  const ApiStatusException(this.statusCode, String message) : super(message);

  final int statusCode;

  bool get isNotFound => statusCode == 404;

  @override
  String toString() => 'ApiStatusException($statusCode): $message';
}

final class ParseException extends ApiException {
  const ParseException([
    super.message = 'Unexpected response from the server.',
  ]);
}
