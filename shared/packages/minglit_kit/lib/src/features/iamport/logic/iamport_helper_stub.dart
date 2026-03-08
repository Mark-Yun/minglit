/// Stub implementation for non-web platforms.
void requestCertificationWeb({
  required String userCode,
  required Map<String, dynamic> data,
  required void Function(Map<String, String>) onResult,
}) {
  throw UnsupportedError('This function is only supported on Web.');
}
