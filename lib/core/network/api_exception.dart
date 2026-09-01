/// Everything the network layer throws, so callers never have to catch
/// `SocketException`, `TimeoutException` or `FormatException` themselves.
///
/// Sealed so a `switch` over a caught failure is exhaustive, which is how the
/// UI decides between "check your connection" and "something went wrong".
sealed class ApiException implements Exception {
  const ApiException(this.message);

  /// Human-readable, safe to show in an error state.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// The request never reached the server, or took too long.
final class NetworkException extends ApiException {
  const NetworkException([super.message = 'Could not reach the server.']);
}

/// The server answered, but with a non-2xx status.
final class ApiStatusException extends ApiException {
  const ApiStatusException(this.statusCode, String message) : super(message);

  final int statusCode;

  /// `404` deserves "not found" wording rather than a generic failure.
  bool get isNotFound => statusCode == 404;

  @override
  String toString() => 'ApiStatusException($statusCode): $message';
}

/// The body arrived but was not the JSON shape the models expect.
final class ParseException extends ApiException {
  const ParseException([
    super.message = 'Unexpected response from the server.',
  ]);
}
